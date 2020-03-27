# BBBlockchain Contract

BBBlockchain is a blockchain-based participation platform to investigate how blockchain technology can improve participatory urban planning. BBBlockchain is an Einstein Center Digital Future research project supported by Berlin‘s six municipal housing associations.

This repository contains the Ethereum smart contracts of BBBlockchain pilots 1 & 2: 

1. RSS timestamping
2. Files timestamping
3. Open votings with hash tokens

All use-cases are designed for permissionless blockchains with using ownership controlling.

For more details see [bbblockchain.de](https://www.bbblockchain.de/).

## Installation
The project uses [Truffle](https://github.com/trufflesuite/truffle) for deployment, migrations, and testing.
The following guide shows how to deploy the BBBlockchain smart contracts locally with [Ganache](https://github.com/trufflesuite/ganache) on a Linux/MacOS setup with basic tooling (vim, Git, NodeJS, NPM).

### 1. Install Truffle Packages and Ganache

- Clone this repository	and install NPM packages

```
git clone https://github.com/ecdf-bbblockchain/bbb-contract
cd ./bbb-contract/
npm install
```
  
- Download Ganache from [trufflesuite.com/ganache](https://www.trufflesuite.com/ganache)
- Start Ganache
- Configure Truffle to connect to local Ganache RPC ```vi truffle-config.js``` and enable the *development* network according to Ganache's settings:
   
```JavaScript
development: {
  host: "127.0.0.1",     // Localhost (default: none)
  port: 7545,            // Standard Ganache port
  network_id: "*",       // Any network (default: none)
},
``` 

### 2. Test Setup
- Execute the Truffle tests:

```bash
truffle test --network development
```

### 3. Deploy BBB
- Create migration script for deploying BBBlockchain:

```bash
vi ./migrations/2_initial_deployment.js
```

```JavaScript
var BBBlockchain = artifacts.require("BBBlockchain");
var StringUtils = artifacts.require("StringUtils");

module.exports = async (deployer, network, accounts) => {
	await deployer.deploy(BBBlockchain, accounts[0]); // Specify the contract owner here!
	await deployer.deploy(StringUtils);
};
```

- Deploy BBBlockchain ```truffle migrate --network development```

### 4. Add an Exemplary Project
- Create migration script for an exemplary project with RSS and files timestamping:

```bash
vi ./migrations/3_test_project.js
```

```JavaScript
var BBBlockchain = artifacts.require("BBBlockchain");
var BBB_Project = artifacts.require("BBB_Project");
var BBB_Project_RSS = artifacts.require("BBB_Usecase_RSS");
var BBB_Project_Files = artifacts.require("BBB_Usecase_Files");
var StringUtils = artifacts.require("StringUtils");

const OWNER = accounts[0];
const CRAWLER = accounts[1]; // This account can add contents but cannot manage the smart contracts

module.exports = async (deployer, network, accounts) => {

  const bbbInstance = await BBBlockchain.deployed();
  
  let projectInstance = null;

  return deployer.deploy(
		BBB_Project, 
		OWNER, 
		"Test Project", 
		"This is just an exemplary test project.",
		"https://example.com/", 
		"Test GmbH",
		Math.floor(Date.now() / 1000) - 50*60*24*10, // start date
		Math.floor(Date.now() / 1000) + 50*60*24*10, // end date
		true) // visible
	.then((instance) => {
	  projectInstance = instance;
	  
	  return bbbInstance.newProject(projectInstance.address);
  })
  .then(() => {
    return deployer.deploy(
			BBB_Project_RSS, 
			OWNER, 
			CRAWLER,
			"https://example.com/rss/feed", // keep in mind that this string will be publicly visible
			true) // active
	})
	.then((instance) => {
	  return projectInstance.addUsecase(instancee.address);
	})
	.then(() => {
	  return deployer.deploy(
			BBB_Project_Files,
			OWNER, 
			CRAWLER,
			"https://example.com/rss/feed", // this use-case requires additional information in the RSS feed (see bbblockchain-wp-plugin)
			true)
	})
	.then((instance) => {
	  return projectInstance.addUsecase(instance.address);
	});

```

- Deploy project ```truffle migrate --network development```
- You now have a deployed BBBlockchain instance with a test use-case that can save timestamps.

### 5. Add an Exemplary Voting
- Create migration script for an exemplary project with RSS and files timestamping:

```bash
vi ./migrations/4_icecream_voting.js
```

**Deployment steps:**

1. Find project "Test Project"
2. Deploy new Hash Tokens smart contract
3. Deploy voting smart contract
4. Add voting options
5. Mount voting smart contract to hash tokens smart contract
6. Add voting as a new use-case to BBBlockchain project

```JavaScript
const BBBlockchain = artifacts.require("BBBlockchain");
const BBB_Project = artifacts.require("BBB_Project");

const BBB_Usecase_Open_Voting = artifacts.require("BBB_Usecase_Open_Voting");
const BBB_Hash_Token = artifacts.require("BBB_Hash_Token");

module.exports = async (deployer, network, accounts) => {
  const OWNER = accounts[0];
  
  let bbbInstance = await BBBlockchain.deployed();

  let projectInstance = null, hashTokenInstance = null, votingInstance = null;
  
  return bbbInstance.projectsSize().then(async (projectsSize) => {
    for(let i = 0; i < projectsSize; i++) {
      let project = await BBB_Project.at(await bbbInstance.projects(i));

      if(await project.name() == "Test Project")
        return project;
    }  
  })
  .then((instance) => {
    projectInstance = instance;
  })
  .then(() => {
    // BBBlockchain actually deploys its own hashToken instance (see constructor) but we use here a separated one
    return deployer.deploy(BBB_Hash_Token);
  })
  .then((instance) => {
    hashTokenInstance = instance;
  })
  .then(() => {
    return deployer.deploy( // address payable _dsi, address payable _urd, bool _active, uint _maximumVote, uint _maximumVoteWeight, BBB_Hash_Token _hashTokens
      BBB_Usecase_Open_Voting,
      OWNER,
      0, // start now
      Math.floor(Date.now() / 1000) + 50*60*24*10, // end date 
      true, // active
      1, // max option (0 or 1)
      1, // max vot weight (1 per voter)
      hashTokenInstance.address,
      "Do you like ice cream?",
      "https://example.com/votings/icecream/rss/feed" // RSS post URL
    );
	})
  .then((instance) => {
	  votingInstance = instance;
  })
  .then(async () => {
    await votingInstance.setOption(0, "Yes");
    await votingInstance.setOption(1, "No");
  })
  .then(async () => {
    let position = await hashTokenInstance.mountContractPosition.call(votingInstance.address);
    await hashTokenInstance.mountContractPosition(votingInstance.address);
    return position;
  })
  .then((contractPosition) => {
    return votingInstance.setVotingTokenPosition(contractPosition["_position"]);
  .then(() => {
    return projectInstance.addUsecase(votingInstance.address);
  });
```

- Deploy voting ```truffle migrate --network development```
- Note: The voting is online now, but nobody has the right to vote

### 6. Add Voting Tokens
- Create 10 hash tokens for voters:

```bash
vi ./migrations/5_iceream_10_new_hashtokens.js
```

```JavaScript
const BBB_Hash_Token = artifacts.require("BBB_Hash_Token");

const SALT = "QJiHn0TIP7c0ZI7j3cJJzFw5P2DfJwv6gcmhj0JfcsOjITHh4dvAp64o15kKeN4c8UWzqnmqibJNZcYf";

module.exports = async (deployer, network, accounts) => {
  const OWNER = accounts[0];
  
  const hashTokenInstance = await BBB_Hash_Token.deployed();
  
  const votingMountPosition = 0; // see mounting at voting deployment
  
  const privateTokens = ["abcd-1010", "lolo-rofl", "super-secret", "top-secret", "1337", "l33d", "c0d3", "§%&/§$%&", "xyz", "zehnz"];
  
  let publicTokens = [];
  
  for(let i = 0; i < privateTokens.length; i++) {
    const privateToken = SALT + privateTokens[i];
    
    let publicToken = await hashTokenInstance.generatePublicToken.call(privateToken, votingMountPosition);
    
    publicTokens = [...publicTokens, publicToken["_votingToken"]];
  }
  
  return hashTokenInstance.addPublicTokens(
    publicTokens,
    publicTokens.map((unused) => { return votingMountPosition; }),
    1, // voting weight
    { from: OWNER }
  );
}
```

- Add new hash tokens ```truffle migrate --network development```

> Note that the private voting tokens got a SALT for better security, which must be appended when voters cast their vote.

## License
- BBBlockchain: [MIT](./LICENSE)
- StringUtils.sol [MIT (commit 8d054f4)](https://github.com/ethereum/dapp-bin/commit/8d054f42867040d355089ca28445cc7ecf056a7b#diff-e1a3ed235327ee046e5fc6cb37e308f1)
- Truffle: [MIT (commit c427f08)](https://github.com/trufflesuite/truffle/blob/develop/LICENSE)