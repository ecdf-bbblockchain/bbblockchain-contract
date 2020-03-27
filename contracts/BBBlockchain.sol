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
import "./BBB_Project.sol";
import "./BBB_Hash_Token.sol";

contract BBBlockchain is BBB_Owned {
    BBB_Project[] public projects;
    uint public projectsSize;

    BBB_Hash_Token public hashTokens;

    constructor(address payable _owner) BBB_Owned(_owner) public { 
        hashTokens = new BBB_Hash_Token();
    }

    // Events
    event NewProject(
        BBB_Project indexed project
    );

    function () external payable {
        revert();
    } 
    
    // New Project
    function newProject(BBB_Project project) public ownerOnly altering {
        require(bytes(project.name()).length > 0);
        require(project.start() > 0);
        require(project.end() > project.start());
                
        projects.push(project);

        emit NewProject(project);

        projectsSize++;
    }

    function destroy() public ownerOnly {
        hashTokens.destroy();

        BBB_Owned.destroy();
    }
}
