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

const BBBlockchain = artifacts.require("BBBlockchain");

contract("BBBlockchain Auth", (accounts) => {
	var bbblockchain;

	before(() => { 
		let votingPosition = -1;
		return BBBlockchain.new(accounts[0])
			.then((instance) => {
				bbblockchain = instance;
			})
			.catch((e) => {
				assert.fail("Could not deploy BBBlockchain " + e);
			});
	});

	it("should reject new authority from wrong account", async () => {
		try {
			await bbblockchain.addAuthority(accounts[2], {from: accounts[2]});
			assert.fail("Unauthorized account");
		} catch (error) {
			// expected error
		}
	});

	it("future owner should not be a authorities", async() => {
		assert.equal(await bbblockchain.isAuthority.call(accounts[0]), false);
	});

	it("should not be an authority yet", async() => {
		assert.equal(await bbblockchain.isAuthority.call(accounts[1]), false);
		assert.equal(await bbblockchain.isAuthority.call(accounts[2]), false);
		assert.equal(await bbblockchain.isAuthority.call(accounts[3]), false);
	});

	it("should add new authority", async () => {
		try {
			await bbblockchain.addAuthority(accounts[2], {from: accounts[0]});
			//await bbblockchain.addAuthority(accounts[2], {from: accounts[1]})
		} catch (error) {
			assert.fail("Unauthorized account error " + error);
		}
	});
	
	it("should not add authority twice", async () => {
		try {
			await bbblockchain.addAuthority(accounts[2], {from: accounts[0]});
			assert.fail("Account already authoroized!");
		} catch (error) {
			// expected error
		}
	});

	it("should add another authority", async () => {
		try {
			await bbblockchain.addAuthority(accounts[3], {from: accounts[0]});
		} catch (error) {
			assert.fail("Unauthorized account error " + error);
		}
	});

	it("should have two authorities", async() => {
		assert.equal(await bbblockchain.isAuthority(accounts[2]), true);
		assert.equal(await bbblockchain.isAuthority(accounts[3]), true);
	});

	it("should not remove authority", async () => {
		try {
			await bbblockchain.removeAuthority(accounts[2], {from: accounts[2]});
			assert.fail("Unauthorized account");
		} catch (error) {
			// expected error
		}

		try {
			await bbblockchain.removeAuthority(accounts[3], {from: accounts[2]});
			assert.fail("Unauthorized account");
		} catch (error) {
			// expected error
		}
	});

	it("should remove first authority", async () => {
		try {
			await bbblockchain.removeAuthority(accounts[2], {from: accounts[0]});
		} catch (error) {
			assert.fail("Unauthorized account error " + error);
		}

		assert.equal(await bbblockchain.isAuthority(accounts[2]), false);
		assert.equal(await bbblockchain.isAuthority(accounts[3]), true);
	});

	it("should remove all authorities", async () => {
		try {
			await bbblockchain.removeAllAuthorities({from: accounts[2]});
			assert.fail("Unauthorized account");
		} catch (error) {
			// expected error
		}

		await bbblockchain.removeAllAuthorities({from: accounts[0]});

		for(var i = 0; i < 5; i++) {
			assert.equal(await bbblockchain.isAuthority(accounts[i]), false);
		}
	});


})