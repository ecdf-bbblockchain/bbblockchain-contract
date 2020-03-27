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

import "./BBB_Owned.sol";
import "./BBB_Usecase.sol";

contract BBB_Project is BBB_Owned {
    enum DetailType { NAME, URL, START, END, VISBILITY, DESCRIPTION, DEVELOPER, STAKEHOLDERS, STAKEHOLDERTYPES, IMAGEURL, WEBSITE, POSTALADDRESS }
    
    string public name;
    string public url;
    string public description;

    string public developer;
    string[] public stakeHolders;
    uint256 public stakeHoldersSize;
    string[] public stakeHolderTypes;
    uint256 public stakeHolderTypesSize;
    string[] public imageUrls;
    uint256 public imageUrlsSize;
    string public website;
    string public postalAddress;
    
    uint256 public start;
    uint256 public end;
    bool public visible;

    BBB_Usecase[] public usecases;
    uint256 public usecasesSize;

    constructor(address payable _owner, string memory _name, string memory _description, string memory _url, string memory _developer, uint _start, uint _end, bool _visible) BBB_Owned(_owner) public {
        require(msg.sender == _owner, "New projects can only be deployed by owner."); // Check for unintentionally assigned owner

        name = _name;
        url = _url;
        start = _start;
        end = _end;
        visible = _visible;
        description = _description;
        developer = _developer;
    }

    // Events
    event NewUsecase(
        uint indexed usecaseIndex,
        uint indexed usecaseType
    );

    event ChangedDetail(
        DetailType indexed detailName
    );

    // Setters
    function setName(string memory _name) public altering ownerOnly { name = _name; emit ChangedDetail(DetailType.NAME); }
    function setUrl(string memory _url) public altering ownerOnly { url = _url; emit ChangedDetail(DetailType.URL); }
    function setStart(uint _start) public altering ownerOnly { start = _start; emit ChangedDetail(DetailType.START); }
    function setEnd(uint _end) public altering ownerOnly { end = _end; emit ChangedDetail(DetailType.END); }
    function setVisible(bool _visible) public altering ownerOnly { visible = _visible; emit ChangedDetail(DetailType.VISBILITY); }
    function setDescription(string memory _description) public altering ownerOnly { description = _description; emit ChangedDetail(DetailType.DESCRIPTION); }

    function setWebsite(string memory _website) public altering ownerOnly { website = _website; emit ChangedDetail(DetailType.WEBSITE); }
    function setPostalAddress(string memory _postalAddress) public altering ownerOnly { postalAddress = _postalAddress; emit ChangedDetail(DetailType.POSTALADDRESS); }

    function setDeveloper(string memory _developer) public altering ownerOnly { developer = _developer; emit ChangedDetail(DetailType.DEVELOPER); }
    
    function addStakeHolder(string memory _stakeHolder) public altering ownerOnly { stakeHolders.push(_stakeHolder); stakeHoldersSize++; emit ChangedDetail(DetailType.STAKEHOLDERS); }
    function addStakeHolderType(string memory _stakeHolderType) public altering ownerOnly { stakeHolderTypes.push(_stakeHolderType); stakeHolderTypesSize++; emit ChangedDetail(DetailType.STAKEHOLDERTYPES); }
    function addImageUrl(string memory _imageUrl) public altering ownerOnly { imageUrls.push(_imageUrl); imageUrlsSize++; emit ChangedDetail(DetailType.IMAGEURL); }

    function resetStakeHolder() public altering ownerOnly { stakeHolders.length = 0; stakeHoldersSize = 0; emit ChangedDetail(DetailType.STAKEHOLDERS); }
    function resetStakeHolderType() public altering ownerOnly { stakeHolderTypes.length = 0; stakeHolderTypesSize = 0; emit ChangedDetail(DetailType.STAKEHOLDERTYPES); }
    function resetImageUrl() public altering ownerOnly { imageUrls.length = 0; imageUrlsSize = 0; emit ChangedDetail(DetailType.IMAGEURL); }

    // Add a new use case
    function addUsecase(BBB_Usecase _usecase) public altering ownerOnly {
        assert(_usecase.getType() >= 0);
        assert(usecasesSize < 2**256 - 1);

        usecases.push(_usecase);

        emit NewUsecase(usecasesSize, _usecase.getType());

        usecasesSize++;
    }

    // Search for use case
    function getUsecase(uint _type) public view returns (address) {
        for(uint i = 0; i < usecasesSize; i++) {
            if(usecases[i].getType() == _type) {
                return address(usecases[i]);
            }
        }

        return address(0);
    }
}
