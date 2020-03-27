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

import "./BBB_Contract_Owned.sol";

contract BBB_Hash_Token is BBB_Contract_Owned {
	mapping(bytes32 => VoteState) internal publicTokens;
	mapping(bytes32 => uint256) internal publicTokenPosition;
	mapping(bytes32 => uint8) internal votingWeights;

	mapping(address => uint) internal voteContracts;
	uint256 internal voteContractsSize = 0;

	uint256 public votingTokensIssued = 0;

    enum VoteState { INVALID, VALID, VALDIDATED }

	constructor() BBB_Contract_Owned() public { }

	/*
	 * Generates a public token corresponding to a given private token and its position.
	 * CAUTION: ONLY CALL VIEW WITHOUT BROADCASTING PARAMETERS!
	 */
	function generatePublicToken(string memory _privateToken, uint _position) public pure returns (bytes32 _publicToken, bytes32 _votingToken, bool _success) {
		require(bytes(_privateToken).length > 24, "Private token too short (at least 24 characters).");

        _votingToken = keccak256(abi.encodePacked(_privateToken, _position));
        _publicToken = keccak256(abi.encodePacked(_votingToken));

        _success = true;
    }

    function addPublicToken(bytes32 _publicToken, uint256 _position, uint8 _votingWeight) public contractOwnerOnly contractAltering returns(bool _success) {
        require(_votingWeight > 0, "Voting weight must be >0.");
        require(publicTokens[_publicToken] == VoteState.INVALID, "Public token is already valid or has been invalidated.");
        assert(publicTokenPosition[_publicToken] == 0);

        publicTokens[_publicToken] = VoteState.VALID;
        publicTokenPosition[_publicToken] = _position;

        if(_votingWeight > 1) // validatePublicToken(...) sets weight to 1 iff it is not set (...for saving storage...)
        	votingWeights[_publicToken] = _votingWeight;

        votingTokensIssued++;
        
        _success = true;
    }

    function addPublicTokens(bytes32[] memory _publicTokens, uint256[] memory _positions, uint8 _votingWeight) public contractOwnerOnly contractAltering returns(bool _success) {
        require(_votingWeight > 0, "Voting weight must be >0.");
        assert(_publicTokens.length > 0);
        require(_publicTokens.length == _positions.length, "Unequal number of _publicTokens.length == _positions.length");

        for(uint i = 0; i < _publicTokens.length; i++) { 
        	bool returnedSuccess = addPublicToken(_publicTokens[i], _positions[i], _votingWeight);

        	require(returnedSuccess, "One of the public tokens is already valid or has been invalidated.");
        }

        _success = true;
    }

    function checkSender(address _contract, uint256 _position) internal view returns (bool) {
    	require(_position < voteContractsSize, "Position overflow.");

    	return voteContracts[_contract] == _position;
    }

    function mountContractPosition(address _votingContract) external contractOwnerOnly contractAltering returns (bool _success, uint256 _position) {
    	_position = voteContractsSize;
        voteContracts[_votingContract] = voteContractsSize;
    	voteContractsSize++;
    	_success = true;
    }

    function checkVotingToken(bytes32 _votingToken, uint256 _position) internal view returns (bool) {
        require(_votingToken.length > 0);

        bytes32 publicToken = keccak256(abi.encodePacked(_votingToken));

        return 
        	publicTokens[publicToken] == VoteState.VALID && // Valid token
        	publicTokenPosition[publicToken] == _position; // Matching position
    }
    
    /*
     * Returns public token state:
     * 0: INVALID
     * 1: VALID
     * 2: VALIDATED
	 *
     * CAUTION: ONLY CALL VIEW WITHOUT BROADCASTING PARAMETERS!
     */
    function getTokenStateByVotingToken(bytes memory _votingToken) public view returns (uint8) {
        require(_votingToken.length > 0);

        VoteState state = publicTokens[keccak256(abi.encodePacked(_votingToken))];

        if(state == VoteState.VALID) 
        	return 1;
        else if(state == VoteState.VALDIDATED)
        	return 2;
        else
        	return 0;
    }

    /*
     * Returns public token state:
     * 0: INVALID
     * 1: VALID
     * 2: VALIDATED
	 *
     * CAUTION: ONLY CALL VIEW WITHOUT BROADCASTING PARAMETERS!
     */
    function getTokenStateByPrivateToken(string memory _privateToken, uint256 _position) public view returns (uint8) {
        require(bytes(_privateToken).length > 0);

        bytes32 votingToken = keccak256(abi.encodePacked(_privateToken, _position));
        bytes32 publicToken = keccak256(abi.encodePacked(votingToken));

        require(publicTokenPosition[publicToken] == _position, "Position does not match with public token.");

        VoteState state = publicTokens[publicToken];

        if(state == VoteState.VALID) 
        	return 1;
        else if(state == VoteState.VALDIDATED)
        	return 2;
        else
        	return 0;
    }

    function validatePublicToken(bytes32 _votingToken, uint256 _position) public contractAltering returns (bool _success, uint8 _votingWeight) {
        require(_votingToken.length > 0, "Validating voting token length must be >0.");
        require(checkSender(msg.sender, _position), "Unauthorized position for msg.sender.");
        require(checkVotingToken(_votingToken, _position), "Invalid voting token.");

        bytes32 publicToken = keccak256(abi.encodePacked(_votingToken));

        
        
        if(publicTokens[publicToken] == VoteState.VALID) { // Check again manually, just to be on the safe side
        	publicTokens[publicToken] = VoteState.VALDIDATED;

        	_success = true;
        	_votingWeight = votingWeights[publicToken];

        	if(_votingWeight == 0)
        		_votingWeight = 1;
		} else {
			_success = false;
			_votingWeight = 0;
		}	        
    }
}
