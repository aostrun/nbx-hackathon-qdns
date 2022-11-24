import {
  decentralizedDNSContract,
  decentralizedDNSContractABI,
} from "./constants.js";

$(document).ready(async function () {
  if (window.ethereum) {
    var web3 = new Web3(window.ethereum);
    try {
      // Request account access if needed
      await window.ethereum.enable();
    } catch (error) {
      console.error(error);
    }
  }

  // Wait for loading completion to avoid race conditions with web3 injection timing.
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });
  console.log(accounts[0]);

  let ddnsContractInstance = new web3.eth.Contract(
    decentralizedDNSContractABI,
    decentralizedDNSContract
  );

  $("body").on("submit", "#buy", function (e) {
    e.preventDefault();

    let domainName = $(this).find('input[name="domainName"]').val();
    let domainOwner = $(this).find('input[name="domainOwner"]').val();

    ddnsContractInstance.methods
      .getPrice(web3.utils.asciiToHex(".q"))
      .call({ from: accounts[0] })
      .then(function (result) {
        let calculatedPrice = web3.utils.fromWei(result, "ether").toString(10);

        ddnsContractInstance.methods
          .register(
            web3.utils.asciiToHex(domainName),
            web3.utils.asciiToHex(".q"),
            domainOwner
          )
          .send({
            from: accounts[0],
            value: web3.utils.toWei(calculatedPrice, "ether"),
          })
          .then(function (result) {
            console.log(result);
            showSuccess(`Domain successfully registered.`);
          })
          .catch((err) => {
            console.log(err);
            return showError("Smart contract call failed");
          });
      })
      .catch((err) => {
        console.log(err);
        return showError("Smart contract call failed");
      });
  });

  $("body").on("submit", "#renew", function (e) {
    e.preventDefault();

    let domainName = $(this).find('input[name="domainName"]').val();

    ddnsContractInstance.methods
      .getPrice(web3.utils.asciiToHex(".q"))
      .call({ from: accounts[0] })
      .then(function (result) {
        console.log(result);
        let calculatedPrice = web3.utils.fromWei(result, "ether").toString(10);
        ddnsContractInstance.methods
          .renewDomainName(
            web3.utils.asciiToHex(domainName),
            web3.utils.asciiToHex(".q")
          )
          .call({
            from: accounts[0],
            value: web3.utils.toWei(calculatedPrice, "ether"),
          })
          .then(function (result) {
            console.log(result);
            showSuccess(`Domain successfully renewed.`);
          })
          .catch((err) => {
            console.log(error);
          });
      })
      .catc((err) => {
        console.log(err);
        return showError("Smart contract call failed");
      });
  });

  $("body").on("submit", "#edit", function (e) {
    e.preventDefault();

    let domainName = $(this).find('input[name="domainName"]').val();
    let domainNewOwner = $(this).find('input[name="domainOwner"]').val();

    ddnsContractInstance.methods
      .edit(
        web3.utils.asciiToHex(domainName),
        web3.utils.asciiToHex(".q"),
        domainNewOwner
      )
      .send({ from: accounts[0] })
      .then(function (result) {
        console.log(result);
        showSuccess(`Domain successfully edited.`);
      })
      .catch((err) => {
        console.log(err);
        return showError("Smart contract call failed");
      });
  });

  $("body").on("submit", "#transfer", function (e) {
    e.preventDefault();

    let domainName = $(this).find('input[name="domainName"]').val();
    let newOwner = $(this).find('input[name="newOwner"]').val();

    ddnsContractInstance.methods
      .transferDomain(
        web3.utils.asciiToHex(domainName),
        web3.utils.asciiToHex(".q"),
        newOwner
      )
      .send({ from: accounts[0] })
      .then(function (result) {
        console.log(result);
        showSuccess(`Domain successfully transferred.`);
      })
      .catch((err) => {
        console.log(err);
        return showError("Smart contract call failed");
      });
  });

  $("body").on("submit", "#price", function (e) {
    e.preventDefault();

    console.log(web3.utils.asciiToHex(".q"));
    ddnsContractInstance.methods
      .getPrice(web3.utils.asciiToHex(".q"))
      .call({ from: accounts[0] })
      .then(function (result) {
        let calculatedPrice = web3.utils.fromWei(result, "ether").toString(10);
        console.log(calculatedPrice);
        showInfo(`Price for the domain is: ${calculatedPrice} Q.`);
      })
      .catch((err) => {
        console.log(err);
        return showError("Smart contract call failed");
      });
  });

  $("body").on("submit", "#getaddress", function (e) {
    e.preventDefault();

    let domainName = $(this).find('input[name="domainName"]').val();

    console.log(domainName, accounts[0]);
    ddnsContractInstance.methods
      .getAddress(
        web3.utils.asciiToHex(domainName),
        web3.utils.asciiToHex(".q")
      )
      .call({ from: accounts[0] })
      .then(function (result) {
        try {
          let domainOwner = result;
          showInfo(`Adress: ${domainOwner}`);
        } catch (error) {
          console.log({ error });
        }
      })
      .cath((err) => {
        console.log(err);
        showError("Smart contract call failed");
      });
  });

  $("body").on("submit", "#getinfo", function (e) {
    e.preventDefault();

    let domainName = $(this).find('input[name="domainName"]').val();

    console.log(domainName, accounts[0]);
    ddnsContractInstance.methods
      .getReceiptList()
      .call({ from: accounts[0] })
      .then(function (result) {
        ddnsContractInstance.methods
          .getReceipt(result[0])
          .call({ from: accounts[0] })
          .then(function (result) {
            try {
              console.log(result);
              const paidPrice = web3.utils.fromWei(result[0], "ether").toString(10);
              showInfo(`
              Cost: ${paidPrice}Q<br>
              Valid from: ${new Date(parseInt(result[1] * 1000))}<br>
              Valid to: ${new Date(parseInt(result[2] * 1000))}<br>
              `);
            } catch (error) {
              console.log({ error });
            }
          })
          .catch((err) => {
            console.log(err);
            showError("Smart contract call failed");
          });
      })
      .cath((err) => {
        console.log(err);
        showError("Smart contract call failed");
      });
  });

  // Attach AJAX "loading" event listener
  $(document).on({
    ajaxStart: function () {
      $("#loadingBox").show();
    },
    ajaxStop: function () {
      $("#loadingBox").hide();
    },
  });

  function showSuccess(message) {
    swal({
      type: "success",
      title: message,
      showConfirmButton: false,
      timer: 1500,
    });
  }

  function showInfo(message) {
    swal("Info", message, "question");
    console.log(message);
  }
  //
  function showError(errorMsg) {
    swal({
      type: "error",
      title: "Oops...",
      text: errorMsg,
    });
    console.log(errorMsg);
  }

  function getUrlParameter(sParam) {
    let sPageURL = decodeURIComponent(window.location.search.substring(1)),
      sURLVariables = sPageURL.split("&"),
      sParameterName,
      i;

    for (i = 0; i < sURLVariables.length; i++) {
      sParameterName = sURLVariables[i].split("=");

      if (sParameterName[0] === sParam) {
        return sParameterName[1] === undefined ? true : sParameterName[1];
      }
    }
  }
  function getBytes(str) {
    var bytes = [];
    for (var i = 0; i < str.length; ++i) {
      bytes.push(str.charCodeAt(i));
    }
    return bytes;
  }
});
