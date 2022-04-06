//Arkius Public Benefit Corporation Privileged & Confidential
// SPDX-License-Identifier: None
pragma solidity ^0.8.2;
pragma abicoder v2;

import "./interfaces/IArkiusMembershipToken.sol";
import "./interfaces/IArkiusCertifierToken.sol";
import "./interfaces/IArkiusAttentionSeekerToken.sol";
import "./interfaces/IEntity.sol";
import './utils/Blacklistable.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @dev CampaignContract This contract is for the certifiers only.
 *
 * Certifier can generate certifications of the entity with this contract.
 *
 * Certification can be of 2 types:- Static and Dynamic.
 *
 */

contract CertificationsUpgradeable is Initializable, UUPSUpgradeable, OwnableUpgradeable, Blacklistable {

    /**
     * @dev Arkius Membership Token instance.
     *
     * Used to call a function from MembershipNFT,
     * which return the member ID of the caller
     */
    IArkiusMembershipToken arkiusMembershipToken;

    /**
     * @dev Arkius Certifier Token instance.
     *
     * Used to call a function from CertifierNFT,
     * which return the certifier ID of the caller
     */
    IArkiusCertifierToken arkiusCertifierToken;

    /**
     * @dev Entity instance.
     *
     * Used to call a functions from Entity.
     */
    IEntity entity;

    uint256 constant INVALID = 0;

    uint256 private START_TIMESTAMP;

    /// Emitted when static certificate is created by the certifier.
    event CreateStaticCertification(uint256 indexed id, string indexed title, address indexed creator);

    /// Emitted when dynamic certificate is created by the certifier.
    event CreateDynamicCertification(uint256 indexed id, string indexed apiLink);

    /// Emitted when certifier certifies static entity.
    event CertifyStaticEntity(uint256 indexed certificationID, uint256 indexed entityID, uint256 indexed certification);

    /// Emitted when certifier update dynamic certificate.
    event UpdateDynamicEntity(uint256 indexed certificationID, string indexed apiLink);

    /// Emitted when seeker applies for certification.
    event ApplyCertification(uint256 indexed certificationID, uint256 indexed entityID);

    /// Emitted when entity or certification is deleted
    event UnsubscribeEntity(uint256 indexed certificationId, uint256 indexed entityId);

    /// Emitted when user subscribe to a certification.
    event SubscribeCertification(uint256 indexed memberID, uint256 indexed certificationID);

    /// Emitted when user unsubscribe to a certification.
    event UnsubscribeCertification(uint256 indexed memberID, uint256 indexed certificationID);

    /// Emitted when certifiers deletes their certificate.
    event DeleteCertification(uint256[] indexed certificationID, uint256[] deleted, address indexed CertificateCreator);

    event MembershipContractUpdated(address membershipContractAddress);

    event CertifierContractUpdated(address certifierContractAddress);

    event EntityContractUpdated(address entityContractAddress);

    event EditCertification(uint256 indexed id, string title, string description, string metadata);

    enum EntityType {product, company, campaign}

    /**
     * Structure of static certification.
     * @param certificationId Id of the certification.
     * @param certifier       Certifier who created that certification.
     * @param title           Title of the certification.
     * @param description     Description of the certification.
     * @param metadataLink    Metadata Link of the certification.
     * @param entityType      Entity type (Company/Product/Campaign).
     * @param score           Mapping from entity Id => certification values.
     */
    struct StaticCertification {
        uint256     certificationId;
        address     certifier;
        string      title;
        string      description;
        string      metadataLink;
        EntityType  entityType;
        mapping(uint256 => uint256) score;           //  entityid OR campignID     =>   certification_value
    }

    /**
     * Structure of dynamic certification.
     * @param certificationId Id of the certification.
     * @param certifier       Certifier who created that certification.
     * @param title           Title of the certification.
     * @param description     Description of the certification.
     * @param entityType      Entity type (Company/Product/Campaign).
     * @param metadataLink    Metadata Link of the certification.
     * @param apiLink         API Link of the Entity.
     */
    struct DynamicCertification {
        uint256    certificationId;
        address    certifier;
        string     title;
        string     description;
        string     metadataLink;
        string     apiLink;     // dynamic
        EntityType entityType;
    }

    /**
     * Return type of certification.
     * @param certificationId Id of the certification.
     * @param certifier       Certifier who created that certification.
     * @param title           Title of the certification.
     * @param description     Description of the certification.
     * @param metadataLink    Metadata Link of the certification.
     * @param entityType      Entity type (Company/Product/Campaign).
     */
    struct ReturnStaticCertification {
        uint256    certificationId;
        address    certifier;
        string     title;
        string     description;
        string     metadataLink;
        EntityType entityType;
    }

    /// @dev mapping from certification Id => static Certificate.
    mapping(uint256 => StaticCertification) private staticCertifications;

    /// @dev maping from certification Id => dynamic certification.
    mapping(uint256 => DynamicCertification) private dynamicCertifications;

    /// @dev mapping from user address => certifications subscribed by the user.
    mapping(address => uint256[]) private memberSubscriptions;

    /// @dev Keeping record of index of every element of memberSubscriptions, helps in deletion.
    mapping(address => mapping(uint256 => uint256)) private idIndexMemberSubscription;

    /// @dev mapping from certification Id => user address subscribed to that certification.
    mapping(uint256 => address[]) private subscriber;

    /// @dev Keeping record of index of every element of subscriber, helps in deletion.
    mapping(uint256 => mapping(address => uint256)) private idIndexSubscriber;

    /// @dev mapping from Certification  => All certified entities or campaigns' IDs.
    mapping(uint256 => uint256[]) private staticCertifiedEntities;

    /// @dev Keeping record of index of every element of staticCertifiedEntities, helps in deletion.
    mapping(uint256 => mapping(uint256 => uint256)) private idIndexStaticCertifiedEntities;

    /// @dev mapping from EntityID  => Certifictaion IDs.
    mapping(uint256 => uint256[]) private staticEntityCertifications;

    /// @dev Keeping record of index of every element of staticEntityCertifications, helps in deletion.
    mapping(uint256 => mapping(uint256 => uint256)) private idIndexStaticEntityCertifications;

    /// @dev mapping from certifier address => CertificationsId created by that certifier.
    mapping(address => uint256[]) private certifierCertifications;

    /// @dev keeping record of every certification created by a certifier.
    mapping(uint256 => uint256) private idIndexCertifierCertifications;

    /// @dev mapping from certification Id => entities that applied for that certification.
    mapping(uint256 => uint256[]) private appliedForCertifications;

    /// @dev keeping record of entities applied for certifications by the seeker.
    mapping(uint256 => mapping(uint256 => uint256)) private idIndexAppliedForCertifications;

    /// @dev array for all Certifications' IDs.
    uint256[] private allCertifications;

    /// @dev Keeping record of index of every element of allCertifications, helps in deletion.
    mapping(uint256 => uint256) private idIndexAllCertifications;

    modifier onlyCertifier() {
        require(arkiusCertifierToken.certifierIdOf(_msgSender()) != INVALID, 'Caller is not a Certifier');
        _;
    }

    modifier onlyMember() {
        require(arkiusMembershipToken.memberIdOf(_msgSender()) != INVALID, 'Caller is not a Member');
        _;
    }

    modifier staticCertifier(uint256 id) {
        require (staticCertifications[id].certifier == _msgSender(), "Caller is not the certificate creator.");
        _;
    }

    modifier dynamicCertifier(uint256 id) {
        require (dynamicCertifications[id].certifier == _msgSender(), "Caller is not the certificate creator.");
        _;
    }

    /**
     * @dev initialize the addresses of MembershipNFT, CertifierNFT & Entity contract.
     *
     * @param memberNFTContract     Address of the MembershipNFT contract.
     * @param certifierNFTContract  Address of the CertifierrNFT contract.
     * @param entityContract     Address of the Entity Contract.
     * @param multisigAddress    Address of the Owner of the SmartContracts.
     */
    function initialize( IArkiusMembershipToken memberNFTContract,
                       IArkiusCertifierToken  certifierNFTContract,
                       IEntity                entityContract,
                       address                blacklistContractAddress,
                       address                multisigAddress) public initializer {

        require(address(memberNFTContract)     != address(0), "Invalid Member Address");
        require(address(certifierNFTContract)  != address(0), "Invalid Certifier Address");
        require(address(entityContract)     != address(0), "Invalid Entity Address");
        require(multisigAddress             != address(0), "Invalid Multisig Address");

        __Ownable_init();
        __Blacklistable_init(blacklistContractAddress);

        arkiusMembershipToken = memberNFTContract;
        arkiusCertifierToken  = certifierNFTContract;
        entity                = entityContract;
        START_TIMESTAMP       = block.timestamp;

        _transferOwnership(multisigAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * this function is for certifier only, to create static certificates.
     * @param timestamp   Current time in second/millisecond.
     * @param types       Entity type (Company/Product/Campaign).
     * @param metadata    Metadata Link of the certification.
     * @param title       Title of the certification.
     * @param description Description of the certification.
     *
     * @return certifiaction ID.
     */
    function createStaticCertification(uint256       timestamp,
                                       EntityType    types,
                                       string calldata metadata,
                                       string calldata title,
                                       string calldata description) onlyCertifier notBlacklisted external returns(uint256) {

        require(timestamp >= START_TIMESTAMP, "Timestamp too old.");

        require(timestamp <= block.timestamp, "Invalid timestamp.");

        uint256 id = hash(_msgSender(), metadata, timestamp);

        require(id != 0 && idIndexAllCertifications[id] == 0, "Invalid Id");
        require(staticCertifications[id].certificationId != id, "ID already exist.");
        require(bytes(title      ).length != 0, "No title provided.");
        require(bytes(description).length != 0, "No description provided.");
        require(bytes(metadata   ).length != 0, "No metadata provided.");

        staticCertifications[id].certificationId = id;
        staticCertifications[id].certifier       = _msgSender();
        staticCertifications[id].title           = title;
        staticCertifications[id].description     = description;
        staticCertifications[id].entityType      = types;
        staticCertifications[id].metadataLink    = metadata;

        certifierCertifications[_msgSender()].push(id);
        idIndexCertifierCertifications[id] = certifierCertifications[_msgSender()].length;

        allCertifications.push(id);
        idIndexAllCertifications[id] = allCertifications.length;

        emit CreateStaticCertification(id, title, _msgSender());

        return id;
    }

    function editCertification(uint256 id,
                               string memory title,
                               string memory description,
                               string memory metadata) onlyCertifier notBlacklisted external {

        require(certificationExists(id) == true, "Invalid Id");

        if (staticCertifications[id].certifier == _msgSender()) {
            if (bytes(title      ).length != 0)   staticCertifications[id].title        = title;
            if (bytes(description).length != 0)   staticCertifications[id].description  = description;
            if (bytes(metadata   ).length != 0)   staticCertifications[id].metadataLink = metadata;
        }
        else if (dynamicCertifications[id].certifier == _msgSender()) {
            if (bytes(title      ).length != 0)   dynamicCertifications[id].title        = title;
            if (bytes(description).length != 0)   dynamicCertifications[id].description  = description;
            if (bytes(metadata   ).length != 0)   dynamicCertifications[id].metadataLink = metadata;
        }
        else {
            revert("You are not the certifier of the certification");
        }

        emit EditCertification(id, title, description, metadata);
    }

    /**
     * this function is for certifier only, to create dynamic certificates.
     * @param timestamp   Current time in second/millisecond.
     * @param types       Entity type (Company/Product/Campaign).
     * @param metadata    Metadata Link of the certification.
     * @param title       Title of the certification.
     * @param description Description of the certification.
     * @param apiLink     Link for the dynamic certificate.
     *
     * @return certifiaction ID.
     */
    function createDynamicCertification(uint256       timestamp,
                                        EntityType    types,
                                        string memory metadata,
                                        string memory title,
                                        string memory description,
                                        string memory apiLink) external onlyCertifier notBlacklisted returns(uint256) {

        require(timestamp >= START_TIMESTAMP, "Timestamp too old.");

        require(timestamp <= block.timestamp, "Invalid timestamp.");

        uint256 id = hash(_msgSender(), metadata, timestamp);

        require(id != 0 && idIndexAllCertifications[id] == 0, "Invalid Id");
        require(dynamicCertifications[id].certificationId != id, "ID already exist.");
        require(bytes(title      ).length != 0, "No title provided.");
        require(bytes(apiLink    ).length != 0, "No API link is provided.");
        require(bytes(description).length != 0, "No description provided.");
        require(bytes(metadata   ).length != 0, "No metadata provided.");

        DynamicCertification memory certification = DynamicCertification(
            id, _msgSender(), title, description, metadata, apiLink, types);

        dynamicCertifications[id] = certification;

        certifierCertifications[_msgSender()].push(id);
        idIndexCertifierCertifications[id] = certifierCertifications[_msgSender()].length;

        allCertifications.push(id);
        idIndexAllCertifications[id] = allCertifications.length;

        emit CreateDynamicCertification(id, apiLink);

        return id;
    }
    
    /** Seeker apply for the certification of the Entities.
     *
     * @param certificationID  ID of the certification
     * @param entityID         ID for the Entity.
     */
    function applyCertification(uint256 certificationID, uint256 entityID) public notBlacklisted {
        require(certificationExists(certificationID) == true, "Invalid certificationID");
        require(entity.entityExist(entityID) == true, "Invalid entityID");
        require(staticCertifications[certificationID].score[entityID] == 0, "Already Certified");
        require(idIndexAppliedForCertifications[certificationID][entityID] == 0, "Already Applied");

        IEntity.ReturnEntity memory returnedEntity = entity.getEntity(entityID);

        require(returnedEntity.creator == _msgSender(), "Not Authorised");

        appliedForCertifications[certificationID].push(entityID);
        idIndexAppliedForCertifications[certificationID][entityID] = appliedForCertifications[certificationID].length;

        emit ApplyCertification(certificationID, entityID);
    }

    /**
     * This function is used to certify Static Entity.
     * It can be called by the owner of this certification only.
     *
     * @param certificationId Id of the certification.
     * @param entityIds       Id of the entities.
     * @param scores          Value that is given to the entities.
     */
    function updateStaticEntity(uint256          certificationId,
                                uint256[] memory entityIds,
                                uint256[] memory scores
                                ) external onlyCertifier() staticCertifier(certificationId) notBlacklisted returns(bool) {

        require(staticCertifications[certificationId].certifier != address(0), "Invalid Id");
        require(entityIds.length == scores.length, "Length Mismatch");


        for (uint256 idx = 0; idx<entityIds.length; idx++) {

            uint256 typeEntity = uint(entity.getEntity(entityIds[idx]).entityType);
            uint256 typeCerti  = uint(staticCertifications[certificationId].entityType);
            uint256 applied    = idIndexAppliedForCertifications[certificationId][entityIds[idx]];

            if (entity.entityExist(entityIds[idx]) == true && typeCerti == typeEntity) {

                if (staticCertifications[certificationId].score[entityIds[idx]] == 0 && applied != 0) {

                    staticCertifications[certificationId].score[entityIds[idx]] = scores[idx];

                    staticCertifiedEntities[certificationId].push(entityIds[idx]);
                    idIndexStaticCertifiedEntities[certificationId][entityIds[idx]] = staticCertifiedEntities[certificationId].length;

                    staticEntityCertifications[entityIds[idx]].push(certificationId);
                    idIndexStaticEntityCertifications[entityIds[idx]][certificationId] = staticEntityCertifications[entityIds[idx]].length;

                    uint256 len  = idIndexAppliedForCertifications[certificationId][entityIds[idx]];
                    uint256 last = appliedForCertifications[certificationId][appliedForCertifications[certificationId].length - 1];

                    appliedForCertifications[certificationId][len - 1] = last;
                    idIndexAppliedForCertifications[certificationId][last] = len;
                    idIndexAppliedForCertifications[certificationId][entityIds[idx]] = 0;
                    appliedForCertifications[certificationId].pop();

                    emit CertifyStaticEntity(certificationId, entityIds[idx], scores[idx]);
                }
                else if (staticCertifications[certificationId].score[entityIds[idx]] != 0) {
                    staticCertifications[certificationId].score[entityIds[idx]] = scores[idx];
                    emit CertifyStaticEntity(certificationId, entityIds[idx], scores[idx]);
                }
            }
        }


        return true;
    }

    /**
     * updates the API Link of dynamic certificate with id = `certificationID`.
     *
     * @param certificationID Id of the certification.
     * @param apiLink         API Link that is to be updated.
     */
    function updateDynamicEntity(uint256 certificationID,
                                 string memory apiLink
                                ) external onlyCertifier() dynamicCertifier(certificationID) notBlacklisted returns(bool) {

        dynamicCertifications[certificationID].apiLink = apiLink;

        emit UpdateDynamicEntity(certificationID, apiLink);

        return true;
    }

    /**
     * This function help the user to subscribe the certification.
     *
     * If the `certificationId` exists, then caller can subscribe that certification.
     *
     * @param certificationID Id of the certificate.
     */
    function subscribeCertification(uint256[] calldata certificationID) external onlyMember notBlacklisted {

        for (uint256 idx = 0; idx < certificationID.length; idx++) {
            _subscribeCertification(certificationID[idx], _msgSender());
        }
    }

    /// Internal function for subscribing a certificate
    function _subscribeCertification(uint256 certificationID, address subscriberAddress) internal {

        bool exists;
        uint256 subscribed;

        exists     = certificationExists(certificationID);
        subscribed = idIndexMemberSubscription[subscriberAddress][certificationID];

        if (exists && subscribed == 0) {

            memberSubscriptions[subscriberAddress].push(certificationID);
            idIndexMemberSubscription[subscriberAddress][certificationID] = memberSubscriptions[subscriberAddress].length;

            subscriber[certificationID].push(subscriberAddress);
            idIndexSubscriber[certificationID][subscriberAddress] = subscriber[certificationID].length;

            emit SubscribeCertification(arkiusMembershipToken.memberIdOf(_msgSender()), certificationID);

        }

    }

    /**
     * This function helps the user to unsubscribe the certification.
     *
     * If the `certificationId` exist, then the caller can unsubscribe that certification.
     *
     * @param certificationId Id of the certificate.
     */
    function unsubscribeCertification(uint256[] calldata certificationId) external onlyMember notBlacklisted {

        for (uint256 idx = 0; idx < certificationId.length; idx++) {

            _unsubscribeCertification(certificationId[idx], _msgSender());
        }

    }

    /// Internal function for unsubscribing a certificate
    function _unsubscribeCertification(uint256 certificationId, address subscriberAddress) internal {

        bool exists         = certificationExists(certificationId);
        uint256 subscribed  = idIndexSubscriber[certificationId][subscriberAddress];

        if (exists && subscribed > 0) {

            address subscriberLastElement = subscriber[certificationId][subscriber[certificationId].length - 1];
            uint idIndex                  = idIndexSubscriber[certificationId][subscriberAddress];

            idIndexSubscriber[certificationId][subscriberLastElement] = idIndex;
            subscriber[certificationId][idIndex - 1]                  = subscriberLastElement;
            idIndexSubscriber[certificationId][subscriberAddress]     = 0;
            subscriber[certificationId].pop();

            uint memberSubscriptionsLastElement = memberSubscriptions[subscriberAddress][memberSubscriptions[subscriberAddress].length - 1];
            idIndex                             = idIndexMemberSubscription[subscriberAddress][certificationId];

            idIndexMemberSubscription[subscriberAddress][memberSubscriptionsLastElement] = idIndex;
            memberSubscriptions[subscriberAddress][idIndex - 1]                          = memberSubscriptionsLastElement;
            idIndexMemberSubscription[subscriberAddress][certificationId]                = 0;
            memberSubscriptions[subscriberAddress].pop();

            emit UnsubscribeCertification(arkiusMembershipToken.memberIdOf(_msgSender()), certificationId);

        }
    }

    function deleteCertification(uint256[] calldata Id) external onlyCertifier() notBlacklisted {

        bool exists;
        bool certificationOwner;

        uint256[] memory deleted = new  uint256[](Id.length);

        for (uint256 idx = 0; idx < Id.length; idx++) {

            certificationOwner = false;

            exists = certificationExists(Id[idx]);
            if (staticCertifications[Id[idx]].certifier  == _msgSender() ||
                dynamicCertifications[Id[idx]].certifier == _msgSender()) {
                certificationOwner = true;
            }

            if (exists && certificationOwner) {

                address[] memory memberSubscriber = getSubscribers(Id[idx]);
                uint256[] memory entitySubscriber = certifiedEntities(Id[idx]);
                deleted[idx] = Id[idx];

                for (uint256 unsubscribe = 0; unsubscribe < memberSubscriber.length; unsubscribe++ ) {
                    _unsubscribeCertification(Id[idx], memberSubscriber[unsubscribe]);
                }

                for (uint256 unsubscribe = 0; unsubscribe < entitySubscriber.length; unsubscribe++ ) {
                    _unsubscribeEntity(Id[idx], entitySubscriber[unsubscribe]);
                }

                if (staticCertifications[Id[idx]].certifier == _msgSender()) {
                    delete staticCertifications[Id[idx]];
                    staticCertifications[Id[idx]].certificationId = Id[idx];
                }
                else {
                    delete dynamicCertifications[Id[idx]];
                    dynamicCertifications[Id[idx]].certificationId = Id[idx];
                }

                uint256 length = certifierCertifications[_msgSender()].length - 1;

                uint256 lastElement = certifierCertifications[_msgSender()][length];
                uint256 index       = idIndexCertifierCertifications[Id[idx]];

                idIndexCertifierCertifications[lastElement]    = index;
                certifierCertifications[_msgSender()][index-1] = lastElement;
                idIndexCertifierCertifications[Id[idx]]        = 0;
                certifierCertifications[_msgSender()].pop();

                lastElement = allCertifications[allCertifications.length - 1];
                index       = idIndexAllCertifications[Id[idx]];

                idIndexAllCertifications[lastElement] = index;
                allCertifications[index-1]            = lastElement;
                idIndexAllCertifications[Id[idx]]     = 0;
                allCertifications.pop();

            }
        }

        emit DeleteCertification(Id, deleted, _msgSender());
    }

    function unsubscribeEntity(uint256 entityId) external notBlacklisted {

        require(_msgSender() == address(entity), "Not Authorised");

        uint256[] memory subscribed = entityCertifications(entityId);

        for (uint idx = 0; idx < subscribed.length; idx++) {

            staticCertifications[subscribed[idx]].score[entityId] = 0;
            _unsubscribeEntity(subscribed[idx], entityId);
        }

    }

    function _unsubscribeEntity(uint256 certificationId, uint256 entityId) internal {

        bool exists         = entity.entityExist(entityId);
        uint256 subscribed  = idIndexStaticCertifiedEntities[certificationId][entityId];

        if (exists && subscribed > 0) {

            uint256 subscriberLastElement = staticCertifiedEntities[certificationId][staticCertifiedEntities[certificationId].length - 1];
            uint256 idIndex               = idIndexStaticCertifiedEntities[certificationId][entityId];

            idIndexStaticCertifiedEntities[certificationId][subscriberLastElement] = idIndex;
            staticCertifiedEntities[certificationId][idIndex - 1]                  = subscriberLastElement;
            idIndexStaticCertifiedEntities[certificationId][entityId]              = 0;
            staticCertifiedEntities[certificationId].pop();

            subscriberLastElement = staticEntityCertifications[entityId][staticEntityCertifications[entityId].length - 1];
            idIndex               = idIndexStaticEntityCertifications[entityId][certificationId];

            idIndexStaticEntityCertifications[entityId][subscriberLastElement] = idIndex;
            staticEntityCertifications[entityId][idIndex - 1]               = subscriberLastElement;
            idIndexStaticEntityCertifications[entityId][certificationId]       = 0;
            staticEntityCertifications[entityId].pop();

            emit UnsubscribeEntity(certificationId, entityId);
        }
    }

    function updateMembershipContract(IArkiusMembershipToken membershipContractAddress) external onlyOwner {
        require(address(membershipContractAddress) != address(0), "Invalid Address");
        arkiusMembershipToken = membershipContractAddress;
        emit MembershipContractUpdated(address(membershipContractAddress));
    }

    function updateCertifierContract(IArkiusCertifierToken certifierContractAddress) external onlyOwner {
        require(address(certifierContractAddress) != address(0), "Invalid Address");
        arkiusCertifierToken = certifierContractAddress;
        emit CertifierContractUpdated(address(certifierContractAddress));
    }

    function updateEntityContract(IEntity entityContractAddress) external onlyOwner {
        require(address(entityContractAddress) != address(0), "Invalid Address");
        entity = entityContractAddress;
        emit EntityContractUpdated(address(entityContractAddress));
    }

    function membershipAddress() external view returns(IArkiusMembershipToken) {
        return arkiusMembershipToken;
    }

    function certifierAddress() external view returns(IArkiusCertifierToken) {
        return arkiusCertifierToken;
    }

    function entityAddress() external view returns(IEntity) {
        return entity;
    }

    function hash(address add, string memory data, uint256 timestamp) internal pure returns(uint256 hashId) {
        hashId = uint(keccak256(abi.encodePacked(add, data, timestamp)));
        return hashId;
    }

    /**
     * return true if there is a certificate with id = `id`.
     *
     * @param id Id of the certificate.
     */
    function certificationExists(uint256 id) public view returns(bool) {
        return (staticCertifications[id].certifier != address(0) ||
                dynamicCertifications[id].certifier != address(0)
                );
    }

    /**
     * returns the certificate value of the entity having id = `entityID`.
     * for the certification with Id = `certificationID`.
     *
     * @param certificationID Id of the certificate.
     * @param entityID        Id of the entity.
     */
    function getStaticCertificate(uint256 certificationID, uint256 entityID) external view returns(uint256) {
        return staticCertifications[certificationID].score[entityID];
    }

    /**
     * returns the api Link of the dynamic certificate having id = `certificationID`.
     *
     * @param certificationID Id of the certificate.
     */
    function getDynamicCertificateLink(uint256 certificationID) external view returns(string memory) {
        return dynamicCertifications[certificationID].apiLink;
    }

    /**
     * returns the details(structure) of the static certification.
     *
     * @param certificationID Id of the certificate.
     */
    function getStaticCertification(uint256 certificationID) external view returns(ReturnStaticCertification memory) {
        return ReturnStaticCertification(
            staticCertifications[certificationID].certificationId,
            staticCertifications[certificationID].certifier,
            staticCertifications[certificationID].title,
            staticCertifications[certificationID].description,
            staticCertifications[certificationID].metadataLink,
            staticCertifications[certificationID].entityType
        );
    }

    /**
     * returns the details(structure) of the Dynamic certification.
     *
     * @param certificationID Id of the certificate.
     */
    function getDynamicCertification(uint256 certificationID) external view returns(DynamicCertification memory) {
        return dynamicCertifications[certificationID];
    }

    /**
     * @dev returns the certification subscribed by the `memberAddress`.
     */
    function getMemberSubscriptions(address memberAddress) external view returns (uint256[] memory) {
        return memberSubscriptions[memberAddress];
    }

    /**
     * @dev returns the subscriber of the `certificationID`.
     */
    function getSubscribers(uint256 certificationID) public view returns(address[] memory) {
        return subscriber[certificationID];
    }

    /**
    * @dev Returns all IDs of Entities in existence.
    */
    function getAllCertifications() public view returns(uint256[] memory) {
        return allCertifications;
    }

    function entityCertifications(uint256 entityId) public view returns(uint256[] memory) {
        return staticEntityCertifications[entityId];
    }

    function certifiedEntities(uint256 certificationId) public view returns(uint256[] memory) {
        return staticCertifiedEntities[certificationId];
    }

    function certifications(address certifierAdd) external view returns(uint256[] memory) {
        return certifierCertifications[certifierAdd];
    }

    function appliedCertifications(uint256 certificationID) external view returns(uint256[] memory) {
        return  appliedForCertifications[certificationID];
    }

    function updateBlacklistContract(IBlacklist _newBlacklist) external override onlyOwner {
        require(
            address(_newBlacklist) != address(0),
            "Blacklistable: new blacklist is the zero address"
        );
        blacklistContract = _newBlacklist;
        emit BlacklistContractChanged(address(_newBlacklist));
    }

}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

interface IArkiusMembershipToken {
    function memberIdOf(address owner) external view returns (uint256);
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

interface IArkiusCertifierToken {
    function certifierIdOf(address owner) external view returns (uint256);

    function burn(address owner, uint256 value) external;
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

interface IArkiusAttentionSeekerToken {
    function attentionSeekerIdOf(address owner) external view returns (uint256);

    function burn(address owner, uint256 value) external;
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IEntity {
    enum IEntityType {product, company, campaign}
    
    struct ReturnEntity{
            uint256     id;
            address     creator;
            IEntityType entityType;
            string      title;
            string      description;
            string      metadata;
    }

    function createEntity(uint256       id,
                          string memory title,
                          IEntityType   types,
                          string memory description,
                          string memory metadata,
                          address attentionSeekerAddress) external;

    function getEntity(uint256 id) external view returns(ReturnEntity memory);

    function entityExist(uint256 id) external view returns(bool);

    function deleteEntity(uint256 id, address attentionSeekerAddress) external;

    function editEntity(uint256       id,
                        string memory title,
                        string memory description,
                        string memory metadata,
                        address attentionSeekerAddress) external;
                }

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;
import "../interfaces/IBlacklist.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Blacklistable is Initializable {

    IBlacklist public blacklistContract;

    event BlacklistContractChanged(address newBlacklist);

    function __Blacklistable_init(address blacklist) internal initializer {
        require(blacklist != address(0), "Blacklistable: Invalid contract address");
        blacklistContract = IBlacklist(blacklist);
    }

    /**
     * @dev Throws if argument account is blacklisted
     */
    modifier notBlacklisted() {
        require(
            !blacklistContract.isBlacklisted(msg.sender),
            "Blacklistable: account is blacklisted"
        );
        _;
    }

    function updateBlacklistContract(IBlacklist _newBlacklist) external virtual;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

interface IBlacklist {

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) external view returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}