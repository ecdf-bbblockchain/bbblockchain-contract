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

/*
Open voting do not anonymize votings (they are traceable but pseudonymized).
Also stores a topic and option strings.
*/

import "./BBB_Usecase.sol";
import "./BBB_Hash_Token.sol";

contract BBB_Usecase_Open_Voting is BBB_Usecase {
    uint256 public start;
    uint256 public end;

    uint256 public countedVotes = 0;

    uint256 public maximumVote;
    uint256 public maximumVoteWeight;

    string public topic;
    mapping(uint256 => string) public options;
    uint256 public optionsSet = 0;

    string public rssPostUrl;

    mapping(uint => uint) public votes;

    bool public overflowPanic = false;

    BBB_Hash_Token public hashTokens;
    uint256 public hashTokenPosition;

    // Events
    event NewVote(
        uint indexed vote,
        bytes32 votingToken
    ); 

    event OverflowPanic(); 


    constructor(address payable _owner, uint256 _start, uint256 _end, bool _active, uint _maximumVote, uint _maximumVoteWeight, BBB_Hash_Token _hashTokens, string memory _topic, string memory _rssPostUrl) BBB_Usecase(_owner, _active) public {
        require(_start == 0 || _start >= now, "_Start must be 0 (for now) or >= now.");
        require(_end == 0 || _end > now, "End date must be 0 (for infinity) or > now.");
        require(_end == 0 || _end >= _start, "End must be >= start.");
        require(_maximumVoteWeight > 0, "Maximum vote weight must be >= 1");
        require((2 ** 256 - 1) / _maximumVoteWeight > 1000000, "Maximum vote weight is to high, at least 1.000.000 possible votes should be possiible.");
        require(bytes(_topic).length > 0, "Topic not set.");

        if(_start == 0) { _start = now; }

        maximumVote = _maximumVote;
        maximumVoteWeight = _maximumVoteWeight;
        hashTokens = _hashTokens;
        topic = _topic;
        start = _start;
        end = _end;
        rssPostUrl = _rssPostUrl;
    }

    function getType() public pure returns (uint) { return 4; }

    function setOption(uint256 _index, string memory _topic) public ownerOnly altering {
        require(bytes(options[_index]).length == 0, "Option already set.");
        require(_index <= maximumVote, "Invalid option index.");

        options[_index] = _topic;
        optionsSet++;
    }

    function vote(uint _vote, bytes32 _votingToken, uint256 _position) public altering timed {
        require(optionsSet - 1 == maximumVote, "Voting not possible, due to missing option descriptions.");

        (bool success, uint8 weight) = hashTokens.validatePublicToken(_votingToken, _position);

        require(!overflowPanic, "Voting stopped due to technical reasons (overflow panic).");
        require(countedVotes < (2 ** 256 - 1) / maximumVoteWeight, "Voting stopped due to technical reasons (voting weight overflow).");
        
        require(success, "Voting token invalid.");
        require(_vote <= maximumVote, "Invalid vote (past maximum).");
        assert(countedVotes < 2**256 - 1);
        assert(weight >= 1);

        votes[_vote] += weight;
        countedVotes++;

        emit NewVote(_vote, _votingToken);

        if(votes[_vote] == (2 ** 256) - 1 || countedVotes == (2 ** 256) - 1) {
            overflowPanic = true;
            emit OverflowPanic();
        }
    }

    function setVotingTokenPosition(uint256 _hashTokenPosition) external altering ownerOnly {
        hashTokenPosition = _hashTokenPosition;
    }

    modifier timed() {
        require(start <= now, "The voting has not begun, yet.");
        require(end == 0 || end > now, "The voting is over.");
        _;
    }
}
