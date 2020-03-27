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

contract BBB_Owned {
    address payable internal owner;

    address internal crawler;

    mapping(uint => address) authorities;
    uint256 authoritiesSize = 0;

    bool public suspended = false;

    constructor(address payable _owner) internal { 
        owner = _owner;
    }

    function changeOwner(address payable _owner) public ownerOnly {
        owner = _owner;
    }

    function isOwner(address payable _sender) view internal returns (bool) {
        return _sender == owner;
    }

    modifier ownerOnly() { 
        require(isOwner(msg.sender)); 
        _;
    }

    function destroy() public ownerOnly {
        assert(msg.sender == owner); // Just to be save 
        selfdestruct(owner);
    }

    // Suspension
    modifier altering() { 
        require(!suspended); 
        _;
    }

    event Suspension (
        bool indexed suspended
    );
    
    function suspend() public authorityOnly {
        suspended = true;
        emit Suspension(true);
    }

    function unsuspend() public ownerOnly {
        suspended = false;
        emit Suspension(false);
    }

    // Crawler Modifier
    function setCrawler(address _crawler) public ownerOnly altering { crawler = _crawler; }
    function isCrawler(address _sender) internal view returns (bool) { return crawler != address(0) && _sender == crawler; }

    // Authorities
    function addAuthority(address _authority) public ownerOnly altering {
        assert(authoritiesSize < 2**256 - 1);

        // Check for uniques
        for(uint i = 0; i < authoritiesSize; i++) {
            if(authorities[i] == _authority)
                revert();
        }   

        authorities[authoritiesSize] = _authority;
        authoritiesSize++;
    }

    function removeAllAuthorities() public ownerOnly altering {
        authoritiesSize = 0;
    }

    function removeAuthority(address _authority) public altering {
        // Check for owner or the athority itself
        require(isOwner(msg.sender) || (_authority == msg.sender && isAuthority(msg.sender)));
        require(authoritiesSize > 0);

        for(uint i = 0; i < authoritiesSize; i++) {
            if(authorities[i] == _authority)
                authorities[i] = address(0x00);
        }
    }

    function isAuthority(address _authority) public view returns (bool) {
        for(uint i = 0; i < authoritiesSize; i++) {
            if(authorities[i] == _authority)
                return true;
        }

        return false;
    }

    modifier crawlerOnly() {
        require(isCrawler(msg.sender) || isOwner(msg.sender)); 
        _;
    }

    modifier authorityOnly() {
        require(isAuthority(msg.sender) || isOwner(msg.sender)); 
        _;
    }

    modifier authorityOrCrawlerOnly() {
        require(isAuthority(msg.sender) || isCrawler(msg.sender) || isOwner(msg.sender)); 
        _;
    }
}
