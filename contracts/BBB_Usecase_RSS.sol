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

import "./BBB_Usecase.sol";
import "./StringUtils.sol";

contract BBB_Usecase_RSS is BBB_Usecase {
    string public rssUrl;

    RSS_Post[] public posts;
    uint256 public postsSize;

    constructor(address payable _owner, address _crawler, string memory _rssUrl, bool _active) BBB_Usecase(_owner, _active) public {
        rssUrl = _rssUrl;
        setCrawler(_crawler);
    }

    function getType() public pure returns (uint) {
        return 0;
    }

    // Structs
    struct RSS_Post {
        string guid;
        string title;
        string author;
        string url;
        string hash;
        uint time;
    }

    // Events
    event NewPost(
        uint indexed index
    );

    // Getter / Setter
    function getRSSPostTitle(uint _i) public view returns (string memory) { return posts[_i].title; }
    function getRSSPostUrl(uint _i) public view returns (string memory) { return posts[_i].url; }
    function getRSSPostTime(uint _i) public view returns (uint) { return posts[_i].time; }
    function getRSSPostHash(uint _i) public view returns (string memory) { return posts[_i].hash; }
    function getRSSPostGuid(uint _i) public view returns (string memory) { return posts[_i].guid; }
    function getRSSPostAuthor(uint _i) public  view returns (string memory) { return posts[_i].author; }

    // New Post
    function newPost(string memory _guid, string memory _title, string memory _author, string memory _url, string memory _hash) public authorityOrCrawlerOnly altering {
        assert(postsSize < 2**256 - 1);

        // Check for uniqueness
        for(uint i = 0; i < postsSize; i++) {
            if(StringUtils.equal(posts[i].guid, _guid)) {
                // STOP because post is already saved
                revert();
            }
        }

        RSS_Post memory post = RSS_Post(_guid, _title, _author, _url, _hash, now);
        posts.push(post);

        emit NewPost(postsSize);

        postsSize++;
    }
}
