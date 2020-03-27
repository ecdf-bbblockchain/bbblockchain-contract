/* MIT Licence:

Copyright (c) 2018-2020 ECDF, TU Berlin https://www.bbblockchain.de

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

const BBB_Usecase_Open_Voting = artifacts.require("BBB_Usecase_Open_Voting");
const BBB_Hash_Token = artifacts.require("BBB_Hash_Token");

contract("BBB_Usecase_Open_Voting", (accounts) => {
	var voting;
	var hashTokens;

	var maxOptions = 5;

	before(() => { 
		let votingPosition = -1;
		return BBB_Hash_Token.new()
			.then((instance) => {
				hashTokens = instance;

				return BBB_Usecase_Open_Voting.new( // _owner, _urd, _active, _maximumVote, _maximumVoteWeight, _votesPerVoter, _hashTokens
					accounts[0], // owner 
					0, // now
					0, // infinite
					true, // active
					maxOptions, // max. vote
					10, // max. vote weight
					hashTokens.address,
					"Question?", // topic,
					"HTTPs://example.com/feed",
					{from: accounts[0]}
				);
			})
			.catch((e) => {
				assert.fail("Could not deploy BBB_Hash_Token " + e);
			})
			.then((instance) => {
				voting = instance;
			});
	});

	it("should mount voting to hashTokens contract", () => {
		return hashTokens.mountContractPosition.call(voting.address, {from: accounts[0]})
			.then((result) => {
				votingPosition = result._position;

				assert.ok(result._success, "Mounting voting position not successfull.");
				assert.equal(result._position, 0, "Unexpected voting position.");

				return hashTokens.mountContractPosition(voting.address, {from: accounts[0]});
			})
			.catch((e) => {
				console.log(e);
				assert.fail("Could not call mount voting position.");
			})
			.then(() => {
				return voting.setVotingTokenPosition(votingPosition, {from: accounts[0]});
			})
			.catch((e) => {
				assert.fail("Could not mount voting position.");
			})
			.catch((e) => {
				assert.fail("Could not set voting position.");
			});
	});

	it("should has no votes", () => {
		return voting.countedVotes.call({from: accounts[1]})
			.then((result) => {
				assert.equal(result.valueOf(), 0);
			})
			.catch((e) => {
				assert.fail("Could not get countedVotes " + e);
			})
			.then(async () => {
				for(let i = 0; i < maxOptions; i++) {
					assert.equal(await voting.votes.call(i), 0, "All votes should be 0");
				}
			});
	});

	let validToken_1_0;

	it("should add valid voting token", async () => {
		validToken_1_0 = await hashTokens.generatePublicToken.call("validvalidvalidvalidvalidvalid1", 0);

		return hashTokens.addPublicToken(validToken_1_0._publicToken, 0, 1, {from: accounts[0]})
			.then(() => {
				return hashTokens.getTokenStateByVotingToken.call(validToken_1_0._votingToken, {from: accounts[0]});
			})
			.then((tokenState) => {
				assert.equal(tokenState, 1, "Public voting token should be valid.");
			})
			.catch((e) => { //catch 
				assert.fail("Voting token couldn't be added/checked. " + e);
			});
	});

	it("should not vote w/o topic options", async () => {
		return voting.vote(0, validToken_1_0._votingToken, 0, {from: accounts[1]})
			.then(() => {
				assert.fail("Should fail because missing topic options.");
			}, async () => {
				// All votes should still be 0
				for(let i = 0; i < maxOptions; i++) {
					assert.equal(await voting.votes.call(i), 0, "All votes should be 0");
				}
			})
			.then(async () => {
				for(let i = 0; i < maxOptions; i++) {
					await voting.setOption(i, "Option " + i, {from: accounts[0]});
				}

				return voting.vote(0, validToken_1_0._votingToken, 0, {from: accounts[1]})
			}).then(() => {
				assert.fail("Should still fail because one missing topic option.");
			}, async () => {
				// All votes should still be 0
				for(let i = 0; i < maxOptions; i++) {
					assert.equal(await voting.votes.call(i), 0, "All votes should be 0");
				}
			})
			.then(async () => {
				await voting.setOption(maxOptions, "Option " + (maxOptions), {from: accounts[0]});
			})
			.then(() => {
				return voting.optionsSet.call();
			})
			.then((optionsSet) => {
				assert.equal(optionsSet, maxOptions + 1, "Wrong number of set options.");
			})
			.catch((e) => {
				assert.fail("Error: " + e);
			})

	});


	it("should not vote with invalid token", async () => {
		invalidToken = await hashTokens.generatePublicToken.call("invalidinvalidinvalidinvalid", 0);

		return voting.vote(0, invalidToken._votingToken, 0, {from: accounts[1]})
			.then(() => {
				assert.fail("Should fail because invalid votingToken.");
			}, async () => {
				// All votes should still be 0
				for(let i = 0; i < maxOptions; i++) {
					assert.equal(await voting.votes.call(i), 0, "All votes should be 0");
				}
			});
	});

	it("should vote with valid token once", async () => {
		return voting.vote(0, validToken_1_0._votingToken, 0, {from: accounts[1]})
			.then(async () => {
				assert.equal(await voting.votes.call(0), 1, "Votes for 0 should be 1");

				// All other votes should still be 0
				for(let i = 1; i < maxOptions; i++)
					assert.equal(await voting.votes.call(i), 0, "All votes other should be 0");
			}, async (e) => { // catch
				assert.fail("Could not vote " + e);
			})
			.then(() => {
				return voting.vote(0, validToken_1_0._votingToken, 0, {from: accounts[1]});
			})
			.then(() => {
				assert.fail("Multiple votes with the same token should not work.");
			}, async () => { // catch

				// Aborted vote should not change votes
				assert.equal(await voting.votes.call(0), 1, "Votes for 0 should still be 1");

				// All other votes should still be 0
				for(let i = 1; i < maxOptions; i++)
					assert.equal(await voting.votes.call(i), 0, "All votes other should still be 0");
			});
	});

	let validToken_2_0;

	it("should vote with another valid token once", async () => {
		validToken_2_0 = await hashTokens.generatePublicToken.call("validvalidvalidvalidvalidvalid2", 0);

		return hashTokens.addPublicToken(validToken_2_0._publicToken, 0, 1, {from: accounts[0]})
			.then(() => {
				return hashTokens.getTokenStateByVotingToken.call(validToken_2_0._votingToken, {from: accounts[0]});
			})
			.then((tokenState) => {
				assert.equal(tokenState, 1, "Public voting token should be valid.");
			})
			.catch((e) => { //catch 
				assert.fail("Voting token couldn't be added/checked. " + e);
			})
			.then(() => {
				return voting.vote(0, validToken_2_0._votingToken, 0, {from: accounts[1]});
			})
			.then(async () => {
				assert.equal(await voting.votes.call(0), 2, "Votes for 0 should be 2");

				// All other votes should still be 0
				for(let i = 1; i < maxOptions; i++)
					assert.equal(await voting.votes.call(i), 0, "All votes other should be 0");
			}, async (e) => { // catch
				assert.fail("Could not vote " + e);
			})
			.then(() => {
				return voting.vote(0, validToken_2_0._votingToken, 0, {from: accounts[1]});
			})
			.then(() => {
				assert.fail("Multiple votes with the same token should not work.");
			}, async () => { // catch

				// Aborted vote should not change votes
				assert.equal(await voting.votes.call(0), 2, "Votes for 0 should still be 2");

				// All other votes should still be 0
				for(let i = 1; i < maxOptions; i++)
					assert.equal(await voting.votes.call(i), 0, "All votes other should still be 0");
			});
	});
})