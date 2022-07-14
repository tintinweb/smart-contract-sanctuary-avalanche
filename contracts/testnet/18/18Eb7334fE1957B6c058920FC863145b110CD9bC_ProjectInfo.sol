/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-13
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

contract Authorization {
    address public owner;
    address public newOwner;
    mapping(address => bool) public isPermitted;
    event Authorize(address user);
    event Deauthorize(address user);
    event StartOwnershipTransfer(address user);
    event TransferOwnership(address user);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier auth {
        require(isPermitted[msg.sender], "Action performed by unauthorized address.");
        _;
    }
    function transferOwnership(address newOwner_) external onlyOwner {
        newOwner = newOwner_;
        emit StartOwnershipTransfer(newOwner_);
    }
    function takeOwnership() external {
        require(msg.sender == newOwner, "Action performed by unauthorized address.");
        owner = newOwner;
        newOwner = address(0x0000000000000000000000000000000000000000);
        emit TransferOwnership(owner);
    }
    function permit(address user) external onlyOwner {
        isPermitted[user] = true;
        emit Authorize(user);
    }
    function deny(address user) external onlyOwner {
        isPermitted[user] = false;
        emit Deauthorize(user);
    }
}

pragma solidity 0.8.13;

contract ProjectInfo is Authorization {

    modifier onlyProjectOwner(uint256 projectId) {
        require(projectOwner[projectId] == msg.sender, "not from owner");
        _;
    }
    modifier isProjectAdminOrOwner(uint256 projectId) {
        require(projectAdmin[projectId].length > 0 &&  
            projectAdmin[projectId][projectAdminInv[projectId][msg.sender]] == msg.sender 
            || projectOwner[projectId] == msg.sender
        , "not from admin");
        _;
    }

    event NewProject(uint256 indexed projectId, address indexed owner);
    event NewProjectVersion(uint256 indexed projectId, uint256 indexed version, bytes32 indexed ipfsCid);
    event SetProjectCurrentVersion(uint256 indexed projectId, uint256 indexed version);
    event Validate(uint256 indexed projectVersionIdx, ProjectStatus status);

    
    event UpdateValidator(address indexed validator);
    event TransferProjectOwnership(uint256 indexed projectId, address indexed newOwner);
    event AddAdmin(uint256 indexed projectId, address indexed admin);
    event RemoveAdmin(uint256 indexed projectId, address indexed admin);

    event NewPackage(uint256 indexed projectId, uint256 indexed packageId, bytes32 indexed ipfsCid);
    event NewPackageVersion(uint256 indexed packageId, uint256 indexed packageVersionId, uint256 version);
    event SetPackageVersionStatus(uint256 indexed packageId, uint256 indexed packageVersionId, PackageVersionStatus status);
    // event AddProjectPackage(uint256 indexed projectId, uint256 indexed packageId);
    // event RemoveProjectPackage(uint256 indexed projectId, uint256 indexed packageId);

    enum ProjectStatus {PENDING, PASSED, FAILED, VOID}
    enum PackageStatus {INACTIVE, ACTIVE}
    enum PackageVersionStatus {WORK_IN_PROGRESS, AUDITING, AUDIT_PASSED, AUDIT_FAILED, VOIDED}

    struct ProjectVersion {
        uint256 projectId;
        uint256 version;
        bytes32 ipfsCid;
        ProjectStatus status;
        uint64 lastModifiedDate;
    }
    struct Package {
        uint256 projectId;
        uint256 currVersionIndex;
        PackageStatus status;
        bytes32 ipfsCid;
    }
    struct PackageVersion {
        uint256 packageId;
        uint256 version;
        PackageVersionStatus status;
        bytes32 ipfsCid;
    }

    // active package list

    uint256 public projectCount;

    // projecct <-> owner / admin
    mapping(uint256 => address) public projectOwner; // projectOwner[projectId] = owner
    mapping(address => uint256[]) public ownersProjects; // ownersProjects[owner][ownersProjectsIdx] = projectId
    mapping(address => mapping(uint256 => uint256)) public ownersProjectsInv; // ownersProjectsInv[owner][projectId] = ownersProjectsIdx
    mapping(uint256 => address) public projectNewOwner; // projectNewOwner[projectId] = newOwner
    mapping(uint256 => address[]) public projectAdmin; // projectAdmin[projectId][idx] = admin
    mapping(uint256 => mapping(address => uint256)) public projectAdminInv; // projectAdminInv[projectId][admin] = idx

    // project meta
    ProjectVersion[] public projectVersions; // projectVersions[projectVersionIdx] = {projectId, version, ipfsCid, PackageVersionStatus}
    mapping(bytes32 => uint256) public projectVersionsInv; // projectVersionsInv[ipfsCid] = projectVersionIdx;
    mapping(uint256 => uint256) public projectCurrentVersion; // projectCurrentVersion[projectId] = projectVersionIdx;
    mapping(uint256 => uint256[]) public projectVersionList; // projectVersionList[projectId][idx] = projectVersionIdx

    // package
    Package[] public packages; // packages[packageId] = {projectId, currVersionIndex, status}
    PackageVersion[] public packageVersions; // packageVersions[packageVersionsId] = {packageId, version, status, ipfsCid}
    mapping(uint256 => uint256[]) public packageVersionsList; // packageVersionsList[packageId][idx] = packageVersionsId
    mapping(uint256 => PackageVersion) public latestAuditedPackageVersion; // latestAuditedPackageVersion[packageId] = {packageId, version, status, ipfsCid}

    // project <-> package
    mapping(uint256 => uint256[]) public projectPackages; // projectPackages[projectId][projectPackagesIdx] = packageId
    mapping(uint256 => mapping(uint256 => uint256)) public projectPackagesInv; // projectPackagesInv[projectId][packageId] = projectPackagesIdx

    address public validator;

    constructor(address _validator) {
        validator = _validator; // FIXME: emit event
    }
    function ownersProjectsLength(address owner) external view returns (uint256 length) {
        length = ownersProjects[owner].length;
    }
    function projectAdminLength(uint256 projectId) external view returns (uint256 length) {
        length = projectAdmin[projectId].length;
    }
    function projectVersionsLength() external view returns (uint256 length) {
        length = projectVersions.length;
    }
    function projectVersionListLength(uint256 projectId) external view returns (uint256 length) {
        length = projectVersionList[projectId].length;
    }
    function packagesLength() external view returns (uint256 length) {
        length = packages.length;
    }
    function packageVersionsLength() external view returns (uint256 length) {
        length = packageVersions.length;
    }
    function packageVersionsListLength(uint256 packageId) external view returns (uint256 length) {
        length = packageVersionsList[packageId].length;
    }
    function projectPackagesLength(uint256 projectId) external view returns (uint256 length) {
        length = projectPackages[projectId].length;
    }

    function updateValidator(address _validator) external onlyOwner {
        validator = _validator;
        emit UpdateValidator(_validator);
    }

    //
    // functions called by project owners
    //
    function newProject(bytes32 ipfsCid) external returns (uint256 projectId) {
        projectId = projectCount;
        projectOwner[projectId] = msg.sender;
        ownersProjectsInv[msg.sender][projectId] = ownersProjects[msg.sender].length;
        ownersProjects[msg.sender].push(projectId);
        projectCount++;
        emit NewProject(projectId, msg.sender);
        newProjectVersion(projectId, ipfsCid);
    }
    function _removeProjectFromOwner(address owner, uint256 projectId) internal {
        // make sure the project ownership is checked !
        uint256 idx = ownersProjectsInv[owner][projectId];
        uint256 lastIdx = ownersProjects[owner].length - 1;
        if (idx < lastIdx) {
            uint256 lastProjectId = ownersProjects[owner][lastIdx];
            ownersProjectsInv[owner][lastProjectId] = idx;
            ownersProjects[owner][idx] = lastProjectId;
        }
        delete ownersProjectsInv[owner][projectId];
        ownersProjects[owner].pop();
    }
    function transferProjectOwnership(uint256 projectId, address newOwner) external onlyProjectOwner(projectId) {
        
        projectNewOwner[projectId] = newOwner;
    }
    function takeProjectOwnership(uint256 projectId) external {
        require(projectNewOwner[projectId] == msg.sender, "not from new owner");
        address prevOwner = projectOwner[projectId];
        projectOwner[projectId] = msg.sender;
        projectNewOwner[projectId] = address(0);

        _removeProjectFromOwner(prevOwner, projectId);

        emit TransferProjectOwnership(projectId, msg.sender);
    }
    function addProjectAdmin(uint256 projectId, address admin) external onlyProjectOwner(projectId) {
        require(projectAdmin[projectId][projectAdminInv[projectId][admin]] != admin, "already a admin");
        projectAdminInv[projectId][admin] = projectAdmin[projectId].length;
        projectAdmin[projectId].push(admin);

        emit AddAdmin(projectId, admin);
    }
    function removeProjectAdmin(uint256 projectId, address admin) external onlyProjectOwner(projectId) {
        uint256 idx = projectAdminInv[projectId][admin];
        uint256 lastIdx = projectAdmin[projectId].length - 1;
        if (idx < lastIdx) {
            address lastAdmin = projectAdmin[projectId][lastIdx];
            projectAdminInv[projectId][lastAdmin] = idx;
            projectAdmin[projectId][idx] = lastAdmin;
        }
        delete projectAdminInv[projectId][admin];
        projectAdmin[projectId].pop();

        emit RemoveAdmin(projectId, admin);
    }
    function newProjectVersion(uint256 projectId, bytes32 ipfsCid) public isProjectAdminOrOwner(projectId) returns (uint256 version) {
        // require(bytes(proejctCid[projectId][version]).length == 0, "project version already set");

        version = projectVersions.length;
        projectVersionList[projectId].push(version); // start from 0

        projectVersionsInv[ipfsCid] = version;
        projectVersions.push(ProjectVersion({
            projectId: projectId,
            version: projectVersionList[projectId].length, // start from 1
            ipfsCid: ipfsCid,
            status: ProjectStatus.PENDING,
            lastModifiedDate: uint64(block.timestamp)
        }));

        emit NewProjectVersion(projectId, version, ipfsCid);
    }
    function setProjectCurrentVersion(uint256 projectId, uint256 versionIdx) external isProjectAdminOrOwner(projectId) {
        ProjectVersion storage version = projectVersions[versionIdx];
        require(version.projectId == projectId, "invalid projectId/versionIdx");
        require(version.status == ProjectStatus.PASSED, "not passed");
        projectCurrentVersion[projectId] = versionIdx;
        emit SetProjectCurrentVersion(projectId, versionIdx);
    }
    function voidVersion(uint256 projectId, uint256 version) external {
        // string verion;
        // uint256 status; // 0 = working, 1 = auditing, 2 = audit-passed, 3 = audit-failed, 4 = voided
        // string ipfsCid;
    }

    function newPackage(uint256 projectId, bytes32 ipfsCid) external isProjectAdminOrOwner(projectId) returns (uint256 packageId) {
        packageId = packages.length;
        packages.push(Package({
            projectId: projectId,
            currVersionIndex: 0,
            status: PackageStatus.ACTIVE,
            ipfsCid: ipfsCid
        }));
        projectPackages[projectId].push(packageId);
        emit NewPackage(projectId, packageId, ipfsCid);
        newPackageVersion(projectId, packageId);
    }
    // TODO: access control ?
    function newPackageVersion(uint256 projectId, uint256 packageId) public isProjectAdminOrOwner(projectId) returns (uint256 packageVersionId) {
        require(packageId < packages.length, "invalid packageId");

        packageVersionId = packageVersions.length;
        packageVersionsList[packageId].push(packageVersionId);
        uint256 version = packageVersionsList[packageId].length;
        packageVersions.push(PackageVersion({
            packageId: packageId,
            version: version,
            status: PackageVersionStatus.WORK_IN_PROGRESS,
            ipfsCid: ""
        }));

        emit NewPackageVersion(packageId, packageVersionId, version);
    }
    function _setPackageVersionStatus(PackageVersion storage packageVersion, uint256 packageVersionId, PackageVersionStatus status) internal {
        packageVersion.status = status;
        emit SetPackageVersionStatus(packageVersion.packageId, packageVersionId, status);
    }
    function setPackageVersionToAuditing(uint256 packageVersionId, bytes32 ipfsCid) external {
        require(packageVersionId < packageVersions.length, "invalid packageVersionId");
        PackageVersion storage packageVersion = packageVersions[packageVersionId];
        require(packageVersion.status == PackageVersionStatus.WORK_IN_PROGRESS, "not in progress");
        packageVersion.ipfsCid = ipfsCid;
        _setPackageVersionStatus(packageVersion, packageVersionId, PackageVersionStatus.AUDITING);
    }
    function voidPackageVersion(uint256 packageVersionId) external {
        require(packageVersionId < packageVersions.length, "invalid packageVersionId");
        PackageVersion storage packageVersion = packageVersions[packageVersionId];
        require(packageVersion.status != PackageVersionStatus.VOIDED, "already voided");
        require(packageVersion.status != PackageVersionStatus.AUDIT_PASSED, "Audit passed version cannot be voided");
        _setPackageVersionStatus(packageVersion, packageVersionId, PackageVersionStatus.VOIDED);
    }
    function setPackageVersionToAuditPassed(uint256 packageVersionId) external {
        require(packageVersionId < packageVersions.length, "invalid packageVersionId");
        PackageVersion storage packageVersion = packageVersions[packageVersionId];
        require(packageVersion.status == PackageVersionStatus.AUDITING, "not under auditing");
        latestAuditedPackageVersion[packageVersion.packageId] = packageVersion;
        _setPackageVersionStatus(packageVersion, packageVersionId, PackageVersionStatus.AUDIT_PASSED);
    } 
    function setPackageVersionToAuditFailed(uint256 packageVersionId) external {
        require(packageVersionId < packageVersions.length, "invalid packageVersionId");
        PackageVersion storage packageVersion = packageVersions[packageVersionId];
        require(packageVersion.status == PackageVersionStatus.AUDITING, "not under auditing");
        _setPackageVersionStatus(packageVersion, packageVersionId, PackageVersionStatus.AUDIT_FAILED);
    }         
    // function addProjectPackage(uint256 projectId, uint256 packageId) external isProjectAdminOrOwner(projectId) {
    //     require(packageId < packages.length, "invalid packageId");
    //     projectPackagesInv[projectId][packageId] = projectPackages[projectId].length;
    //     projectPackages[projectId].push(packageId);

    //     emit AddProjectPackage(projectId, packageId);
    // }
    // function removeProjectPackage(uint256 projectId, uint256 packageId) external isProjectAdminOrOwner(projectId) {
    //     uint256 idx = projectPackagesInv[projectId][packageId];
    //     uint256 lastIdx = projectPackages[projectId].length - 1;
    //     if (idx < lastIdx) {
    //         uint256 lastPackageId = projectPackages[projectId][lastIdx];
    //         projectPackagesInv[projectId][lastPackageId] = idx;
    //         projectPackages[projectId][idx] = lastPackageId;
    //     }
    //     delete projectPackagesInv[projectId][packageId];
    //     projectPackages[projectId].pop();

    //     emit RemoveProjectPackage(projectId, packageId);        
    // }

    //
    // functions called by validators
    //
    function validateProject(uint256 projectVersionIdx, ProjectStatus status) external auth { // or validator
        require(projectVersionIdx < projectVersions.length, "project not exists");
        ProjectVersion storage project = projectVersions[projectVersionIdx];
        require(project.status == ProjectStatus.PENDING || project.status == ProjectStatus.PASSED, "already validated");
        project.status = status;
        project.lastModifiedDate = uint64(block.timestamp);
        emit Validate(projectVersionIdx, status);
    }
}