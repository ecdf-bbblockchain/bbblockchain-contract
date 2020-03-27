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

const BBB_Hash_Token = artifacts.require("BBB_Hash_Token");

contract("BBB_Hash_Token", (accounts) => {
	var hashTokens;

	before(() => { 
		return BBB_Hash_Token.new({from: accounts[0]})
			.then((instance) => {
				hashTokens = instance;
			});
	});


	it("should reject too short private token", async () => {
		try {
			await hashTokens.generatePublicToken("private1", 0);
			assert.fail("The private token is too short and should be rejected.");
		} catch (error) {
			// expected error
		}
	});

	it("should reject adding token from wrong account", () => {
		return hashTokens.generatePublicToken("longlonglonglonglonglong", 0, {from: accounts[1]})
			.then((token) => {
				return addPublicToken(token.valueOf()._publicToken, 0, 1);
			})
			.then((_success) => {
				if(_success)
					assert.fail("Added new public token with unauthorized sender account.");
			})
			.catch(() => {
				// NOP
			});
	});

	it("should mount address to positions", () => {
		return hashTokens.mountContractPosition.call("0x0000000000000000000000000000000000000000", {from: accounts[0]})
			.then((result) => {
				assert.ok(result._success, "Could not mount address to position 0.");
				assert.equal(result._position, 0, "Unexpected contract mount position 0.");

				return hashTokens.mountContractPosition("0x0000000000000000000000000000000000000000", {from: accounts[0]});
			})
			.catch(() => {
				assert.fail("Could not mount address to position 0.");
			})
			.then(() => {
				return hashTokens.mountContractPosition.call("0x0000000000000000000000000000000000000000", {from: accounts[0]});
			})
			.then((result) => {
				assert.ok(result._success, "Could not mount address to position 1.");
				assert.equal(result._position, 1, "Unexpected contract mount position 1.");

				return hashTokens.mountContractPosition("0x0000000000000000000000000000000000000000", {from: accounts[0]});
			})
			.catch(() => {
				assert.fail("Could not mount address to position 1.");
			})
			.then(() => {
				return hashTokens.mountContractPosition("0x0000000000000000000000000000000000000000", {from: accounts[1]});
			})
			.then(() => {
				assert.fail("Mounting to position 2 should fail with unauthorized account.");	
			})			
			.catch(() => {
				// NOP
			})

	});

	var token1_0, token1_1, token2_0, token2_1;

	it("can generate tokens", async() => {
		token1_0 = await hashTokens.generatePublicToken("privateprivateprivateprivate1", 0, {from: accounts[0]});
		token1_1 = await hashTokens.generatePublicToken("privateprivateprivateprivate1", 1, {from: accounts[0]});
		token2_0 = await hashTokens.generatePublicToken("privateprivateprivateprivate2", 0, {from: accounts[0]});
		token2_1 = await hashTokens.generatePublicToken("privateprivateprivateprivate2", 1, {from: accounts[0]});

		let assertToken = (token => { 
			assert.equal(token.valueOf()._publicToken.length, 66, "Public token invalid.");
			assert.equal(token.valueOf()._votingToken.length, 66, "Voting token invalid.");
			assert.notEqual(token.valueOf()._publicToken, token.valueOf()._votingToken, "Voting token and private token have to be different.");
			assert.ok(token.valueOf()._success, "Token not has not been added.");
		});

		[token1_0, token1_1, token2_0, token2_1].map(assertToken);

		let votingTokens = [token1_0, token1_1, token2_0, token2_1].map(token => { return token.valueOf()._votingToken });
		let unique = [...new Set(votingTokens)];
		assert.equal(unique.length, 4, "Voting tokens are not unique.");
	});

	it("should add voting tokens", () => {
		let publicTokens = [
			token1_0.valueOf()._publicToken,
			token1_1.valueOf()._publicToken,
			token2_0.valueOf()._publicToken,
			token2_1.valueOf()._publicToken
		];

		let positions = [0, 1, 0, 1];

		return hashTokens.addPublicTokens(publicTokens, positions, 1, {from: accounts[1]})
			.then(() => {
				assert.fail("Unauthorized account for adding public tokens.");
			})
			.catch(() => {
				return hashTokens.addPublicTokens(publicTokens, positions, 1, {from: accounts[0]});
			})
			.then(() => {
				// NOP
			})
			.catch((e) => {
				assert.fail("Could not add public tokens." + e);
			});
	});

	it("should return 'valid'-state for private token", () => {
		return hashTokens.getTokenStateByPrivateToken.call("privateprivateprivateprivate1", 0, {from: accounts[1]})
			.then((state) => {
				assert.equal(state.valueOf(), 1, "Valid private token 1_0 is invalid");

				return hashTokens.getTokenStateByPrivateToken.call("privateprivateprivateprivate1", 1, {from: accounts[1]})
			})
			.then((state) => {
				assert.equal(state.valueOf(), 1, "Valid private token 1_1 is invalid");

				return hashTokens.getTokenStateByPrivateToken.call("privateprivateprivateprivate2", 0, {from: accounts[1]})
			})
			.then((state) => {
				assert.equal(state.valueOf(), 1, "Valid private token 2_0 is invalid");

				return hashTokens.getTokenStateByPrivateToken.call("privateprivateprivateprivate2", 1, {from: accounts[1]})
			})
			.then((state) => {
				assert.equal(state.valueOf(), 1, "Valid private token 2_1 is invalid");
			});
	});

	it("should return 'valid'-state for valid voting token", () => {
		return hashTokens.getTokenStateByVotingToken.call(token1_0.valueOf()._votingToken, {from: accounts[1]})
			.then((state) => {
				assert.equal(state.valueOf(), 1, "Valid voting token 1_0 is invalid");

				return hashTokens.getTokenStateByVotingToken.call(token1_1.valueOf()._votingToken, {from: accounts[1]})
			})
			.then((state) => {
				assert.equal(state.valueOf(), 1, "Valid voting token 1_1 is invalid");

				return hashTokens.getTokenStateByVotingToken.call(token2_0.valueOf()._votingToken, {from: accounts[1]})
			})
			.then((state) => {
				assert.equal(state.valueOf(), 1, "Valid voting token 2_0 is invalid");

				return hashTokens.getTokenStateByVotingToken.call(token2_1.valueOf()._votingToken, {from: accounts[1]})
			})
			.then((state) => {
				assert.equal(state.valueOf(), 1, "Valid voting token 2_1 is invalid");
			})
			.catch((e) => {
				assert.fail("Could not check voting token validity " + e);
			});
	});

	it("should validate a voting token", () => {
		return hashTokens.validatePublicToken.call(token1_0.valueOf()._votingToken, 0, {from: accounts[0]})
			.then((result) => {
				assert.ok(result._success);
				assert.equal(result._votingWeight, 1, "Expected voting weight 1.");

				return hashTokens.validatePublicToken(token1_0.valueOf()._votingToken, 0, {from: accounts[0]});
			})
			.then((result) => {
				return hashTokens.validatePublicToken(token1_0.valueOf()._votingToken, 0, {from: accounts[0]});	
			})
			.catch((e) => {
				assert.fail("Could not validate token. " + e);
			})
			.catch((e) => {
				// NOP
			})
	});
})