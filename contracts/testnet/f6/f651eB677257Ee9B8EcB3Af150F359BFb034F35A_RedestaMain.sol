// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RedestaMain {
    uint256 public projectID = 0;
    uint public commentID = 0;

    mapping(uint => Projects) public idToProject;
    mapping(address => uint[]) public addrToProjects;
    mapping(uint => Comments[]) public idToComments;
    mapping(address => uint[]) public addrToLiked;
    mapping(address => uint) public commentCount;
    Projects[] public allProjects;
    mapping(address => uint[]) public addrToCommentID;
    //mapping(uint => comments )

    struct Projects {
        address projectOwner;
        uint contractAddr; // ADDRESS OLARAK DEĞİŞTİRİLECEK (BETA)
        string roadmapImgAddr;
        string projectImgAddr;
        string title;
        string mainDescription;
        string shortDescription;
        uint256 id;
        /* uint256 likes;
        uint256 dislikes; */
        uint256 commentCount;
        uint256[] category;
        uint256 nftThreshold;
        uint256 timestamp;
        uint256 supporters;
    }

    struct Comments {
        uint projectID;
        uint comID;
        address author;
        string comment;
        uint likeCount;
        uint dislikeCount;
        uint index;
    }

    function deployProject(
        string memory _roadmapImgAddr,
        string memory _projectImgAddr,
        string memory _title,
        string memory _mainDescription,
        string memory _shortDescription,
        uint[] memory _category,
        uint256 _nftThreshold
    ) public {
        // kontrat oluştur

        // oluşturulan kontratın adresi aşağıdaki push fonksiyonuna eklenecek

        Projects memory tempProject = Projects(
            msg.sender,
            0, // oluşturulan yeni kontrat adresi buraya eklenecek
            _roadmapImgAddr,
            _projectImgAddr,
            _title,
            _mainDescription,
            _shortDescription,
            projectID,
            /*  0,
            0, */
            0,
            _category,
            _nftThreshold,
            block.timestamp,
            0
        );

        allProjects.push(tempProject);
        idToProject[projectID] = tempProject;
        addrToProjects[msg.sender].push(projectID);
        projectID++;
    }

    function addComment(string memory _comment, uint _id) public {
        uint index = idToComments[_id].length;
        idToComments[_id].push(
            Comments(_id, commentID, msg.sender, _comment, 0, 0, index)
        );
    }

    function getComments(uint _id) public view returns (Comments[] memory) {
        return idToComments[_id];
    }

    function getProject(uint _id) public view returns (Projects memory) {
        return idToProject[_id];
    }

    function getFeed() public view returns (Projects[] memory) {
        return allProjects;
    }

    function likeComment(
        uint _comID,
        uint _projectID,
        uint _comIndex
    ) public {
        for (uint i = 0; i < addrToCommentID[msg.sender].length; i++) {
            if (addrToCommentID[msg.sender][i] == _comID) {
                revert("You've already liked this comment.");
            }
        }

        idToComments[_projectID][_comIndex].likeCount++;
        addrToLiked[msg.sender].push(_comID);
    }
}