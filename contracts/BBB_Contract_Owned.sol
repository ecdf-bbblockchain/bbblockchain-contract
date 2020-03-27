pragma solidity >=0.5.0 <0.6.0;

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

contract BBB_Contract_Owned {
	address payable private contractOwner;

	bool public suspended = false;


	constructor() public {
		contractOwner = msg.sender;
	}

	modifier contractOwnerOnly() { 
        require(msg.sender == contractOwner, "Revert by contractOwnerOnly modifier."); 
        _;
    }

    function destroy() public contractOwnerOnly {
        assert(msg.sender == contractOwner); // Just to be save 
        selfdestruct(msg.sender);
    }

    // Suspension
    modifier contractAltering() { 
        require(!suspended, "Revert by contractAltering modifier."); 
        _;
    }

    event ContractSuspension (
        bool indexed suspended
    );
    
    function suspend() public contractOwnerOnly {
        suspended = true;
        emit ContractSuspension(true);
    }

    function unsuspend() public contractOwnerOnly {
        suspended = false;
        emit ContractSuspension(false);
    }
}
