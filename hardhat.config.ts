import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  // solidity: "0.8.17",
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    // qDevNet: {
    //   url: process.env.Q_DEVNET_URL || "http://63.34.190.209:8545",
    //   gas: 2100000,
    //   gasPrice: 50000000000,
    //   accounts:
    //     process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    // },
    qTestNet: {
      url: "https://rpc.qtestnet.org",
      gas: 4100000,
      gasPrice: 50000000000,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
};
export default config;
