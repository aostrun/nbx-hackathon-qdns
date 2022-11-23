pragma solidity >=0.8.9;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@q-dev/contracts/ContractRegistry.sol";
import "./QDNSParameters.sol";
import "./Locals.sol";

contract QDNS is Ownable {
  /** USINGS */
  using SafeMath for uint256;

  /** STRUCTS */
  struct DomainDetails {
    bytes name;
    bytes12 topLevel;
    address owner;
    address addr;
    uint256 expires;
  }

  struct Receipt {
    uint256 amountPaidWei;
    uint256 timestamp;
    uint256 expires;
  }

  ContractRegistry registry;

  /** CONSTANTS */
  uint256 public constant DOMAIN_EXPIRATION_DATE = 365 days;
  uint8 public constant DOMAIN_NAME_MIN_LENGTH = 5;
  uint8 public constant DOMAIN_NAME_EXPENSIVE_LENGTH = 8;
  uint8 public constant TOP_LEVEL_DOMAIN_MIN_LENGTH = 1;
  bytes1 public constant BYTES_DEFAULT_VALUE = bytes1(0x00);

  /** STATE VARIABLES */
  mapping(bytes32 => DomainDetails) public domainNames;
  mapping(address => bytes32[]) public paymentReceipts;
  mapping(bytes32 => Receipt) public receiptDetails;

  /**
   * *************
   * **MODIFIERS**
   * *************
   */
  modifier isAvailable(bytes memory domain, bytes12 topLevel) {
    bytes32 domainHash = getDomainHash(domain, topLevel);
    require(
      domainNames[domainHash].expires < block.timestamp,
      'Domain name is not available.'
    );
    _;
  }

  modifier collectDomainNamePayment(bytes memory domain) {
    uint256 domainPrice = getPrice(domain);
    require(msg.value >= domainPrice, 'Insufficient amount.');
    _;
  }

  modifier isDomainOwner(bytes memory domain, bytes12 topLevel) {
    bytes32 domainHash = getDomainHash(domain, topLevel);
    require(
      domainNames[domainHash].owner == msg.sender,
      'You are not the owner of this domain.'
    );
    _;
  }

  modifier isDomainNameLengthAllowed(bytes memory domain) {
    require(
      domain.length >= DOMAIN_NAME_MIN_LENGTH,
      'Domain name is too short.'
    );
    _;
  }

  modifier isTopLevelLengthAllowed(bytes12 topLevel) {
    require(
      topLevel.length >= TOP_LEVEL_DOMAIN_MIN_LENGTH,
      'The provided TLD is too short.'
    );
    _;
  }

  /**
   * *************
   * ***EVENTS****
   * *************
   */
  event LogDomainNameRegistered(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel
  );

  event LogDomainNameRenewed(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel,
    address indexed owner
  );

  event LogDomainNameEdited(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel,
    address newAddr
  );

  event LogDomainNameTransferred(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel,
    address indexed owner,
    address newOwner
  );

  event LogPurchaseChangeReturned(
    uint256 indexed timestamp,
    address indexed _owner,
    uint256 amount
  );

  event LogReceipt(
    uint256 indexed timestamp,
    bytes domainName,
    uint256 amountInWei,
    uint256 expires
  );

  /**
   * Constructor of the contract
   */
  constructor(address _registry) public {
    registry = ContractRegistry(_registry);
  }

  /*
   * Function to register domain name
   * @param domain - domain name to be registered
   * @param topLevel - domain top level (TLD)
   * @param addr - the addr of the host
   */
  function register(
    bytes memory domain,
    bytes12 topLevel,
    address addr
  )
    public
    payable
    isDomainNameLengthAllowed(domain)
    isTopLevelLengthAllowed(topLevel)
    isAvailable(domain, topLevel)
    collectDomainNamePayment(domain)
  {
    // calculate the domain hash
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // create a new domain entry with the provided fn parameters
    DomainDetails memory newDomain = DomainDetails({
      name: domain,
      topLevel: topLevel,
      owner: msg.sender,
      addr: addr,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // save the domain to the storage
    domainNames[domainHash] = newDomain;

    // create an receipt entry for this domain purchase
    Receipt memory newReceipt = Receipt({
      amountPaidWei: getCurrentPrice(),
      timestamp: block.timestamp,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // calculate the receipt hash/key
    bytes32 receiptKey = getReceiptKey(domain, topLevel);

    // save the receipt key for this `msg.sender` in storage
    paymentReceipts[msg.sender].push(receiptKey);

    // save the receipt entry/details in storage
    receiptDetails[receiptKey] = newReceipt;

    // log receipt issuance
    emit LogReceipt(
      block.timestamp,
      domain,
      getCurrentPrice(),
      block.timestamp + DOMAIN_EXPIRATION_DATE
    );

    // log domain name registered
    emit LogDomainNameRegistered(block.timestamp, domain, topLevel);
  }

  /*
   * Function to extend domain expiration date
   * @param domain - domain name to be registered
   * @param topLevel - top level
   */
  function renewDomainName(bytes memory domain, bytes12 topLevel)
    public
    payable
    isDomainOwner(domain, topLevel)
    collectDomainNamePayment(domain)
  {
    // calculate the domain hash
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // add 365 days (1 year) to the domain expiration date
    domainNames[domainHash].expires += 365 days;

    // create a receipt entity
    Receipt memory newReceipt = Receipt({
      amountPaidWei: getCurrentPrice(),
      timestamp: block.timestamp,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // calculate the receipt key for this domain
    bytes32 receiptKey = getReceiptKey(domain, topLevel);

    // save the receipt id for this msg.sender
    paymentReceipts[msg.sender].push(receiptKey);

    // store the receipt details in storage
    receiptDetails[receiptKey] = newReceipt;

    // log domain name Renewed
    emit LogDomainNameRenewed(block.timestamp, domain, topLevel, msg.sender);

    // log receipt issuance
    emit LogReceipt(
      block.timestamp,
      domain,
      getCurrentPrice(),
      block.timestamp + DOMAIN_EXPIRATION_DATE
    );
  }

  /*
   * Function to edit domain name
   * @param domain - the domain name to be editted
   * @param topLevel - tld of the domain
   * @param newAddr - the new addr for the domain
   */
  function edit(
    bytes memory domain,
    bytes12 topLevel,
    address newAddr
  ) public isDomainOwner(domain, topLevel) {
    // calculate the domain hash - unique id
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // update the new addr
    domainNames[domainHash].addr = newAddr;

    // log change
    emit LogDomainNameEdited(block.timestamp, domain, topLevel, newAddr);
  }

  /*
   * Transfer domain ownership
   * @param domain - name of the domain
   * @param topLevel - tld of the domain
   * @param newOwner - address of the new owner
   */
  function transferDomain(
    bytes memory domain,
    bytes12 topLevel,
    address newOwner
  ) public isDomainOwner(domain, topLevel) {
    // prevent assigning domain ownership to the 0x0 address
    require(newOwner != address(0));

    // calculate the hash of the current domain
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // assign the new owner of the domain
    domainNames[domainHash].owner = newOwner;

    // log the transfer of ownership
    emit LogDomainNameTransferred(
      block.timestamp,
      domain,
      topLevel,
      msg.sender,
      newOwner
    );
  }

  /*
   * Get addr of domain
   * @param domain
   * @param topLevel
   */
  function getAddress(bytes memory domain, bytes12 topLevel)
    public
    view
    returns (address)
  {
    // calculate the hash of the domain
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // return the addr property of the domain from storage
    return domainNames[domainHash].addr;
  }

  function getCurrentPrice() public view returns (uint256) {
    address qdnsParamsAddress = registry.mustGetAddress(REGISTRY_KEY_QDNS_OWNER);
    uint currentPrice = QDNSParameters(qdnsParamsAddress).getUint(REGISTRY_KEY_QDNS_PRICE);
    
    return currentPrice;
  }

  function getLongAddressFee() public view returns (uint256) {
    address qdnsParamsAddress = registry.mustGetAddress(REGISTRY_KEY_QDNS_OWNER);
    uint longAddressFee = QDNSParameters(qdnsParamsAddress).getUint(REGISTRY_KEY_QDNS_LONG_ADDRESS_FEE);
    
    return longAddressFee;
  }

  /*
   * Get price of domain
   * @param domain
   */
  function getPrice(bytes memory domain) public view returns (uint256) {
    // check if the domain name fits in the expensive or cheap categroy
    uint currentPrice = getCurrentPrice();
    uint longAddressFee = getLongAddressFee();

    if (domain.length < DOMAIN_NAME_EXPENSIVE_LENGTH) {
      // if the domain is too short - its more expensive
      return currentPrice + longAddressFee;
    }

    // otherwise return the regular price
    return currentPrice;
  }

  /**
   * Get receipt list for the msg.sender
   */
  function getReceiptList() public view returns (bytes32[] memory) {
    return paymentReceipts[msg.sender];
  }

  /*
   * Get single receipt
   * @param receiptKey
   */
  function getReceipt(bytes32 receiptKey)
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      receiptDetails[receiptKey].amountPaidWei,
      receiptDetails[receiptKey].timestamp,
      receiptDetails[receiptKey].expires
    );
  }

  /*
   * Get (domain name + top level) hash used for unique identifier
   * @param domain
   * @param topLevel
   * @return domainHash
   */
  function getDomainHash(bytes memory domain, bytes12 topLevel)
    public
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(domain, topLevel));
  }

  /*
   * Get recepit key hash - unique identifier
   * @param domain
   * @param topLevel
   * @return receiptKey
   */
  function getReceiptKey(bytes memory domain, bytes12 topLevel)
    public
    view
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked(domain, topLevel, msg.sender, block.timestamp)
      );
  }

  /**
   * Withdraw function
   */
  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}