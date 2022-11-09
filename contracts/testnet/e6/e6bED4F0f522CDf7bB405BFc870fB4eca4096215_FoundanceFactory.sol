pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import "./DaoFactory.sol";
import "./DaoRegistry.sol";
import "../adapters/ManagerAdapter.sol";
import "../adapters/VotingAdapter.sol"; 
import "../adapters/MemberAdapter.sol";
import "../adapters/DynamicEquityAdapter.sol";
import "../adapters/VestedEquityAdapter.sol";
import "../adapters/CommunityEquityAdapter.sol";
import "../extensions/factories/BankExtensionFactory.sol";
import "../extensions/factories/ERC20ExtensionFactory.sol";
import "../extensions/factories/MemberExtensionFactory.sol";
import "../extensions/factories/DynamicEquityExtensionFactory.sol";
import "../extensions/factories/VestedEquityExtensionFactory.sol";
import "../extensions/factories/CommunityEquityExtensionFactory.sol";
import "../libraries/DaoLibrary.sol";
import "../interfaces/IExtension.sol";


contract FoundanceFactory{
    //EVENT
    /**
     * @notice Event emitted when a new Foundance-Agreement has been registered/approved
     * @param  _address address of interacting member
     * @param _projectId The Foundance project Id
     * @param  _name name of Foundance-Agreement
     */
		event FoundanceRegistered(address _address, uint32 _projectId, string _name);
    event FoundanceApproved(address _address, uint32 _projectId,  string _name);
    event FoundanceUpdated(address _address, uint32 _projectId, string _name);

    /**
     * @notice Event emitted when a member has been added/deleted/changed in already registered Foundance-Agreement
     * @param  _address address of Foundance creator
     * @param  _name name of Foundance
     */
    event FoundanceMemberAdded(address _address, string _name);
    event FoundanceMemberDeleted(address _address, string _name);
    event FoundanceMemberChanged(address _address, string _name);
     /**
     * @notice Event emitted when a new Dao has been created based upon a registered Foundance
     * @dev The event is too big, people will have to call `function getExtensionAddress(bytes32 extensionId)` to get the addresses
     * @param  _creatorAddress add of the member summoning the DAO
     * @param _projectId The Foundance project Id
     * @param  _daoAdress address of DaoRegistry
     */
    event FoundanceLive(
      address _creatorAddress,
      uint32 _projectId,
      address _daoAdress,
      address _bankExtensionAdress,
      address _erc20ExtensionAddress,
      address _memberExtensionAddress,
      address _dynamicEquityExtensionAddress,
      address _vestedEquityExtensionAddress,
      address _communityEquityExtensionAddress
    ); 

    //CORE
    address daoFactoryAddress = 0x1A3aB9c502cE7eeb486208dE3a724Fcb0BA58B43;
    //EXTENSION
    address bankExtensionFactoryAddress = 0x590aB43Ca47D1aa7B4c0C42ce12Caa5Cc2edd4d7;
    address erc20ExtensionFactoryAddress = 0xbe7307B54eb531e351673af3350551528B4942e0;
    address memberExtensionFactoryAddress = 0xe04dD2a10Ce73cc33Ed596db5e784f3037d136A0;
    address dynamicEquityExtensionFactoryAddress = 0x31456465b874942E53E600eB1E6B9a8dA4b1F683;
    address vestedEquityExtensionFactoryAddress = 0xfe54026D5F21e5Ea176962CF33910402F6731ccb;
    address communityEquityExtensionFactoryAddress = 0x0dc02A7b9164F609dD7cdC3A8d1176E70f114Db5;
    //ADAPTER
    address managerAdapterAddress = 0xe6d6558805B3DEAbF9B05a68397C15E494EC9Fba;
    address votingAdapterAddress = 0xb95Cf45721B2a7aCcc49C813e7229c36453A6918;
    address memberAdapterAddress = 0xA5cEA58B551Deb8Bb4fe5C028C38AAA6970c9fa1;
    address dynamicEquityAdapterAddress = 0xb13B2073a390F943b9bFBb18058Da8Bd8d06b0Ce;
    address vestedEquityAdapterAddress = 0xa90E7D04361aD90F1D634cB20619B72524F03f82;
    address communityEquityAdapterAddress = 0x669aFbdc6A88aBb28868D12646ad8949bCb8F142;

    //CORE
    DaoFactory daoFactory; 
    //EXTENSION
    BankExtensionFactory bankExtensionFactory;
    ERC20ExtensionFactory erc20ExtensionFactory;
    MemberExtensionFactory memberExtensionFactory;
    DynamicEquityExtensionFactory dynamicEquityExtensionFactory;
    VestedEquityExtensionFactory vestedEquityExtensionFactory;
    CommunityEquityExtensionFactory communityEquityExtensionFactory;
    //ADAPTER
    ManagerAdapter managerAdapter;
    VotingAdapter votingAdapter;
    MemberAdapter memberAdapter;
    DynamicEquityAdapter dynamicEquityAdapter;
    VestedEquityAdapter vestedEquityAdapter;
    CommunityEquityAdapter communityEquityAdapter;

    constructor() {        
        isAdmin[msg.sender]=true;
        //CORE
        daoFactory = DaoFactory(daoFactoryAddress);
        //EXTENSION
        bankExtensionFactory = BankExtensionFactory(bankExtensionFactoryAddress);
        erc20ExtensionFactory = ERC20ExtensionFactory(erc20ExtensionFactoryAddress);
        memberExtensionFactory = MemberExtensionFactory(memberExtensionFactoryAddress);
        dynamicEquityExtensionFactory = DynamicEquityExtensionFactory(dynamicEquityExtensionFactoryAddress);
        vestedEquityExtensionFactory = VestedEquityExtensionFactory(vestedEquityExtensionFactoryAddress);
        communityEquityExtensionFactory = CommunityEquityExtensionFactory(communityEquityExtensionFactoryAddress);
        //ADAPTER
        managerAdapter = ManagerAdapter(managerAdapterAddress);
        votingAdapter = VotingAdapter(votingAdapterAddress);
        memberAdapter = MemberAdapter(memberAdapterAddress);
        dynamicEquityAdapter = DynamicEquityAdapter(dynamicEquityAdapterAddress);
        vestedEquityAdapter = VestedEquityAdapter(vestedEquityAdapterAddress);
        communityEquityAdapter = CommunityEquityAdapter(communityEquityAdapterAddress);
    }

    mapping(string => Foundance.FoundanceConfig) private registeredFoundance;
    mapping(uint32 => string) private registeredFoundanceWithId;
    mapping(address => bool) public isAdmin;

    modifier onlyCreator(string calldata foundanceName) {
        require(registeredFoundance[foundanceName].creatorAddress == msg.sender, "Only creatorAddress can access");
        _;
    }
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can access");
        _;
    }

    /**
     * @notice Register a Foundance Dao   
     * @dev The foundanceName must be unique and not previously registered.
     * @param foundanceName Name of the Dao
     * @param projectId THe internal project identifier for correlating projects and DAOs
     * @param factoryMemberConfigArray FactoryMemberConfig Array including all relevant data
     * @param tokenConfig *
     * @param votingConfig *
     * @param epochConfig *
     * @param dynamicEquityConfig *
     * @param vestedEquityConfig *
     * @param communityEquityConfig *
     **/ 
    function registerFoundance( 
      string calldata foundanceName,
      uint32 projectId,
      Foundance.FactoryMemberConfig[] memory factoryMemberConfigArray,
      Foundance.TokenConfig calldata tokenConfig,
      Foundance.VotingConfig calldata  votingConfig,
      Foundance.EpochConfig calldata epochConfig,
      Foundance.DynamicEquityConfig calldata dynamicEquityConfig, 
      Foundance.VestedEquityConfig calldata vestedEquityConfig, 
      Foundance.CommunityEquityConfig calldata communityEquityConfig 
    ) external{
        require(isNameUnique(foundanceName),"Foundance-DAO or Foundance-Agreement with this name already created.");
        require(isIdUnique(projectId),"Foundance-Agreement with this projectId has already been created");        
        registeredFoundanceWithId[projectId] = foundanceName;
        Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];
        foundance.creatorAddress = msg.sender;
        //FOUNDANCE
        foundance.projectId = projectId;
        foundance.tokenConfig = tokenConfig; 	
        foundance.votingConfig = votingConfig; 	
        foundance.epochConfig = epochConfig; 	
        foundance.dynamicEquityConfig = dynamicEquityConfig; 	
        foundance.vestedEquityConfig = vestedEquityConfig; 	
        foundance.communityEquityConfig = communityEquityConfig; 	
        //MEMBER
        for(uint256 i=0;i<factoryMemberConfigArray.length;i++){
          factoryMemberConfigArray[i].foundanceApproved = false;
          foundance.factoryMemberConfigArray.push(factoryMemberConfigArray[i]);
          foundance.factoryMemberConfigIndex[factoryMemberConfigArray[i].memberAddress]=i+1;
        }
        foundance.factoryMemberConfigArray[foundance.factoryMemberConfigIndex[msg.sender]-1].foundanceApproved = true;
        foundance.foundanceStatus = Foundance.FoundanceStatus.REGISTERED;
        emit FoundanceRegistered(msg.sender, projectId, foundanceName);
     }

     /**
     * @notice Edit a Foundance Dao   
     * @dev The foundanceName must be previously registered.
     * @param foundanceName Name of the Dao
     * @param projectId THe internal project identifier for correlating projects and DAOs
     * @param factoryMemberConfigArray FactoryMemberConfig Array including all relevant data
     * @param tokenConfig *
     * @param votingConfig *
     * @param epochConfig *
     * @param dynamicEquityConfig *
     * @param communityEquityConfig *
     **/
     
    function updateFoundance( 
      string calldata foundanceName,
      uint32 projectId,
      Foundance.FactoryMemberConfig[] memory factoryMemberConfigArray,
      Foundance.TokenConfig calldata tokenConfig,
      Foundance.VotingConfig calldata  votingConfig,
      Foundance.EpochConfig calldata epochConfig,
      Foundance.DynamicEquityConfig calldata dynamicEquityConfig,
      Foundance.VestedEquityConfig calldata vestedEquityConfig, 
      Foundance.CommunityEquityConfig calldata communityEquityConfig 
    ) external onlyCreator(foundanceName){
        Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];
        //FOUNDANCE
        foundance.tokenConfig = tokenConfig; 	
        foundance.votingConfig = votingConfig; 	
        foundance.epochConfig = epochConfig; 	
        foundance.dynamicEquityConfig = dynamicEquityConfig; 	
        foundance.communityEquityConfig = communityEquityConfig;
        foundance.vestedEquityConfig = vestedEquityConfig; 	
        emit FoundanceUpdated(msg.sender, projectId, foundanceName);

        //MEMBER
        Foundance.FactoryMemberConfig[] memory tempfactoryMemberConfigArray = foundance.factoryMemberConfigArray;
        for(uint256 i=0;i<tempfactoryMemberConfigArray.length;i++){
          foundance.factoryMemberConfigIndex[tempfactoryMemberConfigArray[i].memberAddress]=0;
          foundance.factoryMemberConfigArray.pop();          
        }
        
        for(uint256 i=0;i<factoryMemberConfigArray.length;i++){
          factoryMemberConfigArray[i].foundanceApproved = false;
          foundance.factoryMemberConfigArray.push(factoryMemberConfigArray[i]);
          foundance.factoryMemberConfigIndex[factoryMemberConfigArray[i].memberAddress]=i+1;
        }
        foundance.factoryMemberConfigArray[foundance.factoryMemberConfigIndex[msg.sender]-1].foundanceApproved = true;
        foundance.foundanceStatus = Foundance.FoundanceStatus.REGISTERED;
        //emit FoundanceUpdated(msg.sender, projectId, foundanceName);
     }

    /**
    * @notice FactoryMemberConfig approves a registered Foundance-Agreement  
    * @param foundanceName Name of Foundance-DAO
    **/ 
    function approveFoundance(
      string calldata foundanceName
    ) external{
        Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];
        require(foundanceMemberExists(foundance, msg.sender), "FactoryMemberConfig doesnt exists in this Foundance-Agreement.");
        foundance.factoryMemberConfigArray[foundance.factoryMemberConfigIndex[msg.sender]-1].foundanceApproved = true;
        emit FoundanceApproved(msg.sender,foundance.projectId,foundanceName);
        if(_isFoundanceApproved(foundance)){
          foundance.foundanceStatus=Foundance.FoundanceStatus.APPROVED;
        }
    }

    /**
    * @notice Checks if the Foundance-Agreement is approved by all registered members.  
    * @param foundanceName Name of the Foundance DAO
    **/ 
    function isFoundanceApproved(string calldata foundanceName) external view returns(bool){
        Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];    
        return _isFoundanceApproved(foundance);
    }

    /**
    * @notice Checks if the Foundance-Agreement is approved by all registered members.  
    * @param foundance Foundance
    **/ 
    function _isFoundanceApproved(
      Foundance.FoundanceConfig storage foundance
    ) internal view returns(bool){
        for(uint256 i=0;i<foundance.factoryMemberConfigArray.length;i++){
          if(!foundance.factoryMemberConfigArray[i].foundanceApproved) return false;
        }
        return true;
    }

    /**
    * @notice Revokes approval for all members within a Foundance-Agreement
    * @param foundance Foundance
    **/ 
    function revokeApproval(Foundance.FoundanceConfig storage foundance) internal returns(Foundance.FoundanceConfig storage){
      for(uint256 i=0;i<foundance.factoryMemberConfigArray.length;i++){
      	foundance.factoryMemberConfigArray[i].foundanceApproved=false;
      }
      return foundance;
    }

    /**
    * @notice Create a Foundance-DAO based upon an already approved Foundance-Agreement 
    * @dev The Foundance-Agreement must be approved by all members
    * @dev This function must be accessed by the Foundance-Agreement creator
    * @param foundanceName Name of the Foundance-DAO
    **/ 
    function createFoundance(
      string calldata foundanceName
    ) external onlyCreator(foundanceName){
				Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];
    	  require(
          _isFoundanceApproved(foundance),
          "Foundance-Agreement is not approved by all members"
        );				
        //CREATE_CORE
        daoFactory.createDao(foundanceName, msg.sender);
        address daoAddress = daoFactory.getDaoAddress(foundanceName);
        DaoRegistry dao = DaoRegistry(daoAddress);
        //CREATE_EXTENSION
        bankExtensionFactory.create(dao,foundance.tokenConfig.maxExternalTokens);
        erc20ExtensionFactory.create(dao,foundance.tokenConfig.tokenName,DaoLibrary.UNITS,foundance.tokenConfig.tokenSymbol,foundance.tokenConfig.decimals);
        memberExtensionFactory.create(dao);
        dynamicEquityExtensionFactory.create(dao);
        vestedEquityExtensionFactory.create(dao);
        communityEquityExtensionFactory.create(dao);
        //GET_ADDRESSES
        address bankExtensionAddress = bankExtensionFactory.getExtensionAddress(daoAddress);
        address erc20ExtensionAddress = erc20ExtensionFactory.getExtensionAddress(daoAddress);
        address memberExtensionAddress = memberExtensionFactory.getExtensionAddress(daoAddress);
        address dynamicEquityExtensionAddress = dynamicEquityExtensionFactory.getExtensionAddress(daoAddress);
        address vestedEquityExtensionAddress = vestedEquityExtensionFactory.getExtensionAddress(daoAddress);
        address communityEquityExtensionAddress = communityEquityExtensionFactory.getExtensionAddress(daoAddress);
        //DAO_REGISTRY_addExtension
        dao.addExtension(DaoLibrary.BANK_EXT, IExtension(bankExtensionAddress));
        dao.addExtension(DaoLibrary.ERC20_EXT,IExtension(erc20ExtensionAddress));
        dao.addExtension(DaoLibrary.MEMBER_EXT,IExtension(memberExtensionAddress));
        dao.addExtension(DaoLibrary.DYNAMIC_EQUITY_EXT,IExtension(dynamicEquityExtensionAddress));
        dao.addExtension(DaoLibrary.VESTED_EQUITY_EXT,IExtension(vestedEquityExtensionAddress));
        dao.addExtension(DaoLibrary.COMMUNITY_EQUITY_EXT,IExtension(communityEquityExtensionAddress));
        //DAO_REGISTRY_setConfiguration
        dao.setConfiguration(keccak256("erc20.transfer.type"), 2);
        //DAO_REGISTRY_setAddressConfiguration
        dao.setAddressConfiguration(keccak256(abi.encodePacked("governance.role.", managerAdapterAddress)), DaoLibrary.UNITS);
        {
          //DAO_REGISTRY_ADD_ADAPTERS
          DaoFactory.Adapter[] memory adapterList = new DaoFactory.Adapter[](10);
            adapterList[0] = DaoFactory.Adapter(DaoLibrary.FOUNDANCE_FACTORY,address(this),uint128(0));
            adapterList[1] = DaoFactory.Adapter(DaoLibrary.BANK_EXT,bankExtensionAddress,uint128(0));
            adapterList[2] = DaoFactory.Adapter(DaoLibrary.ERC20_EXT,erc20ExtensionAddress,uint128(64));
            adapterList[3] = DaoFactory.Adapter(DaoLibrary.MEMBER_EXT,memberExtensionAddress,uint128(66));
            adapterList[4] = DaoFactory.Adapter(DaoLibrary.MANAGER_ADPT,managerAdapterAddress,uint128(59));
            adapterList[5] = DaoFactory.Adapter(DaoLibrary.VOTING_ADPT,votingAdapterAddress,uint128(0));
            adapterList[6] = DaoFactory.Adapter(DaoLibrary.MEMBER_ADPT,memberAdapterAddress,uint128(66));
            adapterList[7] = DaoFactory.Adapter(DaoLibrary.DYNAMIC_EQUITY_ADPT,dynamicEquityAdapterAddress,uint128(127));
            adapterList[8] = DaoFactory.Adapter(DaoLibrary.VESTED_EQUITY_ADPT,vestedEquityAdapterAddress,uint128(127));
            adapterList[9] = DaoFactory.Adapter(DaoLibrary.COMMUNITY_EQUITY_ADPT,communityEquityAdapterAddress,uint128(127));
          daoFactory.addAdapters(dao, adapterList);
          //BANK_EXT_ACL
          adapterList = new DaoFactory.Adapter[](6);
            adapterList[0] = DaoFactory.Adapter(DaoLibrary.ERC20_EXT,erc20ExtensionAddress,uint128(4));
            adapterList[1] = DaoFactory.Adapter(DaoLibrary.VOTING_ADPT,votingAdapterAddress,uint128(4));
            adapterList[2] = DaoFactory.Adapter(DaoLibrary.MEMBER_ADPT,memberAdapterAddress,uint128(17));
            adapterList[3] = DaoFactory.Adapter(DaoLibrary.DYNAMIC_EQUITY_ADPT,dynamicEquityAdapterAddress,uint128(7));
            adapterList[4] = DaoFactory.Adapter(DaoLibrary.VESTED_EQUITY_ADPT,dynamicEquityAdapterAddress,uint128(7));
            adapterList[5] = DaoFactory.Adapter(DaoLibrary.COMMUNITY_EQUITY_ADPT,communityEquityAdapterAddress,uint128(15));
          daoFactory.configureExtension(dao, bankExtensionAddress, adapterList);
          //MEMBER_EXT_ACL
          adapterList = new DaoFactory.Adapter[](2);
            adapterList[0] = DaoFactory.Adapter(DaoLibrary.FOUNDANCE_FACTORY,address(this),uint128(7));
            adapterList[1] = DaoFactory.Adapter(DaoLibrary.MEMBER_ADPT,memberAdapterAddress,uint128(7));
          daoFactory.configureExtension(dao, memberExtensionAddress, adapterList);
          //DYNAMIC_EQUITY_EXT_ACL
          adapterList = new DaoFactory.Adapter[](2);
            adapterList[0] = DaoFactory.Adapter(DaoLibrary.DYNAMIC_EQUITY_ADPT,dynamicEquityAdapterAddress,uint128(7));
            adapterList[1] = DaoFactory.Adapter(DaoLibrary.MEMBER_EXT,memberAdapterAddress,uint128(7));
          daoFactory.configureExtension(dao, dynamicEquityExtensionAddress, adapterList);
          //VESTED_EQUITY_EXT_ACL
          adapterList = new DaoFactory.Adapter[](2);
            adapterList[0] = DaoFactory.Adapter(DaoLibrary.VESTED_EQUITY_ADPT,vestedEquityAdapterAddress,uint128(7));
            adapterList[1] = DaoFactory.Adapter(DaoLibrary.MEMBER_EXT,memberAdapterAddress,uint128(7));
          daoFactory.configureExtension(dao, vestedEquityExtensionAddress, adapterList);
          //COMMUNITY_EQUITY_EXT_ACL
          adapterList = new DaoFactory.Adapter[](2);
            adapterList[0] = DaoFactory.Adapter(DaoLibrary.COMMUNITY_EQUITY_ADPT,communityEquityAdapterAddress,uint128(7));
            adapterList[1] = DaoFactory.Adapter(DaoLibrary.MEMBER_EXT,memberAdapterAddress,uint128(7));
          daoFactory.configureExtension(dao, communityEquityExtensionAddress, adapterList);
        }
        //CONFIGURE
        BankExtension bank = BankExtension(bankExtensionAddress);
        bank.registerPotentialNewInternalToken(dao, DaoLibrary.UNITS);
        votingAdapter.configureDao(dao, foundance.votingConfig);
        _createFoundanceInternal(dao,memberExtensionAddress,foundance);
        //REMOVE_ACL_FOUNDANCE_FACTORY
        {
          DaoFactory.Adapter[] memory adapterList = new DaoFactory.Adapter[](1);
            adapterList[0] = DaoFactory.Adapter(DaoLibrary.MEMBER_ADPT,memberAdapterAddress,uint128(7));
          daoFactory.configureExtension(dao, memberExtensionAddress, adapterList);
        }
        //FINALIZE
        dao.finalizeDao();
				foundance.foundanceStatus=Foundance.FoundanceStatus.LIVE;
        emit FoundanceLive(msg.sender,foundance.projectId,daoAddress,bankExtensionAddress,erc20ExtensionAddress, memberExtensionAddress, dynamicEquityExtensionAddress, vestedEquityExtensionAddress, communityEquityExtensionAddress);
    }
    
    function _createFoundanceInternal(
      DaoRegistry dao,
      address memberExtensionAddress,
      Foundance.FoundanceConfig storage foundance
    ) internal {
        //CONFIGURE_ADAPTER
        votingAdapter.configureDao(dao, foundance.votingConfig);
        //CREATE_EXTENSION
        MemberExtension member = MemberExtension(memberExtensionAddress);
        member.setMemberEnvironment(dao, foundance.dynamicEquityConfig, foundance.vestedEquityConfig, foundance.communityEquityConfig, foundance.epochConfig);
        //CONFIGURE_EXTENSION_PER_MEMBER
        for(uint256 i=0;i<foundance.factoryMemberConfigArray.length;i++){
          Foundance.FactoryMemberConfig memory factoryMemberConfig = foundance.factoryMemberConfigArray[i];
          if(factoryMemberConfig.dynamicEquityMemberConfig.memberAddress!=factoryMemberConfig.memberAddress){
            factoryMemberConfig.dynamicEquityMemberConfig.memberAddress==address(0);
          }
          if(factoryMemberConfig.vestedEquityMemberConfig.memberAddress==factoryMemberConfig.memberAddress){
            factoryMemberConfig.vestedEquityMemberConfig.memberAddress==address(0);
          }
          if(factoryMemberConfig.communityEquityMemberConfig.memberAddress==factoryMemberConfig.memberAddress){
            factoryMemberConfig.communityEquityMemberConfig.memberAddress==address(0);
          }
          member.setMember(
            dao,
            factoryMemberConfig.memberConfig
          );
          member.setMemberSetup(
            dao, 
            factoryMemberConfig.dynamicEquityMemberConfig,
            factoryMemberConfig.vestedEquityMemberConfig,
            factoryMemberConfig.communityEquityMemberConfig
          );
        }
    }
   
    
    /**
    * @notice Checks if the member exists within the Foundance
    * @dev The Foundance must exist
    * @param foundance Foundance
    * @param _member Address of member
    **/ 
    function foundanceMemberExists(
      Foundance.FoundanceConfig storage foundance, 
      address _member
    ) internal view returns(bool){
        require(foundance.creatorAddress!=address(0x0),"There is no foundance with this name");
        uint memberIndex = foundance.factoryMemberConfigIndex[_member];
        if(memberIndex==0){
      	  return false;
        }
        return true;
    }

    // Admin Functions
    function addAdmins(address[] calldata admins) public onlyAdmin{
      for(uint256 i=0;i<admins.length;i++){
        isAdmin[admins[i]] = true;
      }
    }
    function removeAdmins(address[] calldata admins) public onlyAdmin{
      for(uint256 i=0;i<admins.length;i++){
        isAdmin[admins[i]] = false;
      }
    }
    function setIdtoDaoName(uint32 projectId, string calldata name) public onlyAdmin{
      registeredFoundanceWithId[projectId] = name;
    }
    function setFoundanceConfig(
      string calldata foundanceName,
      uint32 projectId,
      Foundance.FactoryMemberConfig[] memory factoryMemberConfigArray,
      Foundance.TokenConfig calldata tokenConfig,
      Foundance.VotingConfig calldata  votingConfig,
      Foundance.EpochConfig calldata epochConfig,
      Foundance.DynamicEquityConfig calldata dynamicEquityConfig, 
      Foundance.CommunityEquityConfig calldata communityEquityConfig,
      Foundance.VestedEquityConfig calldata vestedEquityConfig, 
      address creatorAddress,
      uint8 foundanceStatus
      ) public onlyAdmin{
        registeredFoundanceWithId[projectId] = foundanceName;
        Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];
        foundance.creatorAddress = creatorAddress;
        //FOUNDANCE
        foundance.projectId = projectId;
        foundance.tokenConfig = tokenConfig; 	
        foundance.votingConfig = votingConfig; 	
        foundance.epochConfig = epochConfig; 	
        foundance.dynamicEquityConfig = dynamicEquityConfig; 	
        foundance.communityEquityConfig = communityEquityConfig;
        foundance.vestedEquityConfig = vestedEquityConfig;          
          
        //MEMBER
        for(uint256 i=0;i<factoryMemberConfigArray.length;i++){
          foundance.factoryMemberConfigIndex[factoryMemberConfigArray[i].memberAddress]=i+1;
          factoryMemberConfigArray[i].foundanceApproved = false;
          foundance.factoryMemberConfigArray.push(factoryMemberConfigArray[i]);
        }
        foundance.foundanceStatus = Foundance.FoundanceStatus(foundanceStatus);
    }

    //view Functions

    function isNameUnique(string calldata foundanceName) public view returns(bool){       
       return daoFactory.getDaoAddress(foundanceName)==address(0x0) && registeredFoundance[foundanceName].creatorAddress==address(0x0);   
    }
    function isIdUnique(uint32 projectId) public view returns(bool){       
      return bytes(registeredFoundanceWithId[projectId]).length==0;     
    }

    function getFoundanceMembers(string calldata foundanceName) public view returns(Foundance.FactoryMemberConfig[] memory _factoryMemberConfigArray){
       return registeredFoundance[foundanceName].factoryMemberConfigArray;       
    }
    function getFoundanceTokenConfig(string calldata foundanceName) public view returns(Foundance.TokenConfig memory _factoryMemberConfigArray){
       return registeredFoundance[foundanceName].tokenConfig;       
    }
    function getFoundanceDynamicEquityConfig(string calldata foundanceName) public view returns(Foundance.DynamicEquityConfig memory _factoryMemberConfigArray){
       return registeredFoundance[foundanceName].dynamicEquityConfig;       
    }
    function getFoundanceVotingConfig(string calldata foundanceName) public view returns(Foundance.VotingConfig memory){
       return registeredFoundance[foundanceName].votingConfig;       
    }
    function getFoundanceEpochConfig(string calldata foundanceName) public view returns(Foundance.EpochConfig memory){
       return registeredFoundance[foundanceName].epochConfig;       
    }
    function getFoundanceCommunityEquityConfig(string calldata foundanceName) public view returns(Foundance.CommunityEquityConfig memory){
       return registeredFoundance[foundanceName].communityEquityConfig;       
    }
    function getFoundanceCreatorAddress(string calldata foundanceName) public view returns(address){
       return registeredFoundance[foundanceName].creatorAddress;       
    }
    function getFoundanceStatus(string calldata foundanceName) public view returns(Foundance.FoundanceStatus){
       return registeredFoundance[foundanceName].foundanceStatus;       
    }
    function getFoundancewithId(uint32 projectId) public view returns(string memory){
       return registeredFoundanceWithId[projectId];       
    }
    function getFoundanceConfigWithId(uint32 projectId) public view returns(Foundance.FoundanceConfigView memory){
      string memory foundanceName  = registeredFoundanceWithId[projectId];
      Foundance.FoundanceConfig storage config = registeredFoundance[foundanceName];
      Foundance.FoundanceConfigView memory configView = Foundance.FoundanceConfigView(config.creatorAddress, foundanceName, config.foundanceStatus, config.factoryMemberConfigArray, config.tokenConfig, config.votingConfig, config.epochConfig, config.dynamicEquityConfig, config.vestedEquityConfig, config.communityEquityConfig);
      return configView;       
    }
    
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

library Foundance {
  //CONFIG
  struct FoundanceConfig {
    address creatorAddress;
    uint32 projectId;
    FoundanceStatus foundanceStatus;
    FactoryMemberConfig[] factoryMemberConfigArray;
    mapping(address => uint256) factoryMemberConfigIndex;
    TokenConfig tokenConfig;
    VotingConfig votingConfig;
    EpochConfig epochConfig;
    DynamicEquityConfig dynamicEquityConfig;
    VestedEquityConfig vestedEquityConfig;
    CommunityEquityConfig communityEquityConfig;
  }
  
  struct FoundanceConfigView {
    address creatorAddress;
    string foundanceName;
    FoundanceStatus foundanceStatus;
    FactoryMemberConfig[] factoryMemberConfigArray;
    TokenConfig tokenConfig;
    VotingConfig votingConfig;
    EpochConfig epochConfig;
    DynamicEquityConfig dynamicEquityConfig;
    VestedEquityConfig vestedEquityConfig;
    CommunityEquityConfig communityEquityConfig;
  }

  struct TokenConfig {
    string tokenName;
    string tokenSymbol;
    uint8 maxExternalTokens;
    uint8 decimals;
  }

  struct VotingConfig {
    VotingType votingType;
    uint256 votingPeriod;
    uint256 gracePeriod;
    uint256 disputePeriod;
    uint256 passRateMember;
    uint256 passRateToken;
    uint256 supportRequired;
  }

  struct EpochConfig {
    uint256 epochDuration;
    uint256 epochReview;
    uint256 epochStart;
    uint256 epochLast;
  }

  struct DynamicEquityConfig {
    uint256 riskMultiplier;
    uint256 timeMultiplier;
  }

  struct VestedEquityConfig {
    uint256 vestingCadenceInS;
  }

  struct CommunityEquityConfig {
    AllocationType allocationType;
    uint256 allocationTokenAmount;
    uint256 tokenAmount;
  }

  //MEMBER_CONFIG
  struct FactoryMemberConfig {
    address memberAddress;
    bool foundanceApproved;
    MemberConfig memberConfig;
    DynamicEquityMemberConfig dynamicEquityMemberConfig;
    VestedEquityMemberConfig vestedEquityMemberConfig;
    CommunityEquityMemberConfig communityEquityMemberConfig;
  }

  struct MemberConfig {
    address memberAddress;
    uint256 initialAmount;
    uint256 initialPeriod;
    bool appreciationRight;
  }

  struct DynamicEquityMemberConfig {
    address memberAddress;
    uint256 suspendedUntil;
    uint256 availability;
    uint256 availabilityThreshold;
    uint256 salary;
    uint256 salaryYear;
    uint256 withdrawal;
    uint256 withdrawalThreshold;
    uint256 expense;
    uint256 expenseThreshold;
    uint256 expenseCommitted;
    uint256 expenseCommittedThreshold;
  }

  struct VestedEquityMemberConfig {
    address memberAddress;
    uint256 tokenAmount;
    uint256 duration;
    uint256 start;
    uint256 cliff;
  }

  struct CommunityEquityMemberConfig {
    address memberAddress;
    uint256 singlePaymentAmountThreshold;
    uint256 totalPaymentAmountThreshold;
    uint256 totalPaymentAmount;
  }

  //ENUM
  enum FoundanceStatus {
    REGISTERED,
    APPROVED,
    LIVE
  }

  enum VotingType {
    PROPORTIONAL,
    WEIGHTED,
    QUADRATIC,
    OPTIMISTIC,
    COOPERATIVE
  }

  enum AllocationType {
    POOL,
    EPOCH
  }

  enum ProposalStatus {
    NOT_STARTED,
    IN_PROGRESS,
    DONE,
    FAILED
  }

  enum VotingState {
    NOT_STARTED,
    TIE,
    PASS,
    NOT_PASS,
    IN_PROGRESS,
    GRACE_PERIOD,
    DISPUTE_PERIOD
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "./DaoRegistry.sol";
import "./CloneFactory.sol";

contract DaoFactory is CloneFactory {
    struct Adapter {
        bytes32 id;
        address addr;
        uint128 flags;
    }

    // daoAddr => hashedName
    mapping(address => bytes32) public daos;
    // hashedName => daoAddr
    mapping(bytes32 => address) public addresses;

    address public identityAddress;

    /**
     * @notice Event emitted when a new DAO has been created.
     * @param _address The DAO address.
     * @param _name The DAO name.
     */
    event DAOCreated(address _address, string _name);

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "invalid addr");
        identityAddress = _identityAddress;
    }

    /**
     * @notice Creates and initializes a new DaoRegistry with the DAO creator and the transaction sender.
     * @notice Enters the new DaoRegistry in the DaoFactory state.
     * @dev The daoName must not already have been taken.
     * @param daoName The name of the DAO which, after being hashed, is used to access the address.
     * @param creator The DAO's creator, who will be an initial member.
     */
    function createDao(string calldata daoName, address creator) external {
        bytes32 hashedName = keccak256(abi.encode(daoName));
        require(
            addresses[hashedName] == address(0x0),
            string(abi.encodePacked("name ", daoName, " already taken"))
        );
        DaoRegistry dao = DaoRegistry(_createClone(identityAddress));

        address daoAddr = address(dao);
        addresses[hashedName] = daoAddr;
        daos[daoAddr] = hashedName;

        dao.initialize(creator, msg.sender);
        //slither-disable-next-line reentrancy-events
        emit DAOCreated(daoAddr, daoName);
    }

    /**
     * @notice Returns the DAO address based on its name.
     * @return The address of a DAO, given its name.
     * @param daoName Name of the DAO to be searched.
     */
    function getDaoAddress(string calldata daoName)
        external
        view
        returns (address)
    {
        return addresses[keccak256(abi.encode(daoName))];
    }

    /**
     * @notice Adds adapters and sets their ACL for DaoRegistry functions.
     * @dev A new DAO is instantiated with only the Core Modules enabled, to reduce the call cost. This call must be made to add adapters.
     * @dev The message sender must be an active member of the DAO.
     * @dev The DAO must be in `CREATION` state.
     * @param dao DaoRegistry to have adapters added to.
     * @param adapters Adapter structs to be added to the DAO.
     */
    function addAdapters(DaoRegistry dao, Adapter[] calldata adapters)
        external
    {
        require(dao.isMember(msg.sender), "not member");
        //Registring Adapters
        require(
            dao.state() == DaoRegistry.DaoState.CREATION,
            "this DAO has already been setup"
        );

        for (uint256 i = 0; i < adapters.length; i++) {
            //slither-disable-next-line calls-loop
            dao.replaceAdapter(
                adapters[i].id,
                adapters[i].addr,
                adapters[i].flags,
                new bytes32[](0),
                new uint256[](0)
            );
        }
    }

    /**
     * @notice Configures extension to set the ACL for each adapter that needs to access the extension.
     * @dev The message sender must be an active member of the DAO.
     * @dev The DAO must be in `CREATION` state.
     * @param dao DaoRegistry for which the extension is being configured.
     * @param extension The address of the extension to be configured.
     * @param adapters Adapter structs for which the ACL is being set for the extension.
     */
    function configureExtension(
        DaoRegistry dao,
        address extension,
        Adapter[] calldata adapters
    ) external {
        require(dao.isMember(msg.sender), "not member");
        //Registring Adapters
        require(
            dao.state() == DaoRegistry.DaoState.CREATION,
            "this DAO has already been setup"
        );

        for (uint256 i = 0; i < adapters.length; i++) {
            //slither-disable-next-line calls-loop
            dao.setAclToExtensionForAdapter(
                extension,
                adapters[i].addr,
                adapters[i].flags
            );
        }
    }

    /**
     * @notice Removes an adapter with a given ID from a DAO, and adds a new one of the same ID.
     * @dev The message sender must be an active member of the DAO.
     * @dev The DAO must be in `CREATION` state.
     * @param dao DAO to be updated.
     * @param adapter Adapter that will be replacing the currently-existing adapter of the same ID.
     */
    function updateAdapter(DaoRegistry dao, Adapter calldata adapter) external {
        require(dao.isMember(msg.sender), "not member");
        require(
            dao.state() == DaoRegistry.DaoState.CREATION,
            "this DAO has already been setup"
        );

        dao.replaceAdapter(
            adapter.id,
            adapter.addr,
            adapter.flags,
            new bytes32[](0),
            new uint256[](0)
        );
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import '../modifiers/AdapterGuard.sol';
import '../modifiers/MemberGuard.sol';
import '../interfaces/IExtension.sol';
import '../libraries/DaoLibrary.sol';

contract DaoRegistry is MemberGuard, AdapterGuard {
    /**
     * EVENTS
     */
    event SubmittedProposal(bytes32 proposalId, uint256 flags);
    event SponsoredProposal(
        bytes32 proposalId,
        uint256 flags,
        address votingAdapter
    );
    event ProcessedProposal(bytes32 proposalId, uint256 flags);
    event AdapterAdded(
        bytes32 adapterId,
        address adapterAddress,
        uint256 flags
    );
    event AdapterRemoved(bytes32 adapterId);
    event ExtensionAdded(bytes32 extensionId, address extensionAddress);
    event ExtensionRemoved(bytes32 extensionId);
    event UpdateDelegateKey(address memberAddress, address newDelegateKey);
    event ConfigurationUpdated(bytes32 key, uint256 value);
    event AddressConfigurationUpdated(bytes32 key, address value);

    /**
     * ENUM
     */
    enum DaoState {
        CREATION,
        READY
    }

    enum MemberFlag {
        EXISTS,
        JAILED
    }

    enum ProposalFlag {
        EXISTS,
        SPONSORED,
        PROCESSED
    }

    enum AclFlag {
        REPLACE_ADAPTER,
        SUBMIT_PROPOSAL,
        UPDATE_DELEGATE_KEY,
        SET_CONFIGURATION,
        ADD_EXTENSION,
        REMOVE_EXTENSION,
        NEW_MEMBER,
        JAIL_MEMBER
    }

    /**
     * STRUCTURES
     */
    struct Proposal {
        /// the structure to track all the proposals in the DAO
        address adapterAddress; /// the adapter address that called the functions to change the DAO state
        uint256 flags; /// flags to track the state of the proposal: exist, sponsored, processed, canceled, etc.
    }
 
    struct Member {
        /// the structure to track all the members in the DAO
        uint256 flags; /// flags to track the state of the member: exists, etc
    }

    struct Checkpoint {
        /// A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    struct DelegateCheckpoint {
        /// A checkpoint for marking the delegate key for a member from a given block
        uint96 fromBlock;
        address delegateKey;
    }

    struct AdapterEntry {
        bytes32 id;
        uint256 acl;
    }

    struct ExtensionEntry {
        bytes32 id;
        mapping(address => uint256) acl;
        bool deleted;
    }

    /**
     * PUBLIC VARIABLES
     */

    /// @notice internally tracks deployment under eip-1167 proxy pattern
    bool public initialized = false;

    /// @notice The dao state starts as CREATION and is changed to READY after the finalizeDao call
    DaoState public state;

    /// @notice The map to track all members of the DAO with their existing flags
    mapping(address => Member) public members;
    /// @notice The list of members
    address[] private _members;

    /// @notice delegate key => member address mapping
    mapping(address => address) public memberAddressesByDelegatedKey;

    /// @notice The map that keeps track of all proposasls submitted to the DAO
    mapping(bytes32 => Proposal) public proposals;
    /// @notice The map that tracks the voting adapter address per proposalId: proposalId => adapterAddress
    mapping(bytes32 => address) public votingAdapter;
    /// @notice The map that keeps track of all adapters registered in the DAO: sha3(adapterId) => adapterAddress
    mapping(bytes32 => address) public adapters;
    /// @notice The inverse map to get the adapter id based on its address
    mapping(address => AdapterEntry) public inverseAdapters;
    /// @notice The map that keeps track of all extensions registered in the DAO: sha3(extId) => extAddress
    mapping(bytes32 => address) public extensions;
    /// @notice The inverse map to get the extension id based on its address
    mapping(address => ExtensionEntry) public inverseExtensions;
    /// @notice The map that keeps track of configuration parameters for the DAO and adapters: sha3(configId) => numericValue
    mapping(bytes32 => uint256) public mainConfiguration;
    /// @notice The map to track all the configuration of type Address: sha3(configId) => addressValue
    mapping(bytes32 => address) public addressConfiguration;

    /// @notice controls the lock mechanism using the block.number
    uint256 public lockedAt;

    /**
     * INTERNAL VARIABLES
     */

    /// @notice memberAddress => checkpointNum => DelegateCheckpoint
    mapping(address => mapping(uint32 => DelegateCheckpoint)) _checkpoints;
    /// @notice memberAddress => numDelegateCheckpoints
    mapping(address => uint32) _numCheckpoints;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO's creator, who will be an initial member
     * @param payer The account which paid for the transaction to create the DAO, who will be an initial member
     */
    //slither-disable-next-line reentrancy-no-eth
    function initialize(address creator, address payer) external {
        require(!initialized, 'dao already initialized');
        initialized = true;
        potentialNewMember(msg.sender);
        potentialNewMember(creator);
        potentialNewMember(payer);
    }

    /**
     * ACCESS CONTROL
     */

    /**
     * @dev Sets the state of the dao to READY
     */
    function finalizeDao() external {
        require(
            isActiveMember(this, msg.sender) || isAdapter(msg.sender),
            'not allowed to finalize'
        );
        state = DaoState.READY;
    }

    /**
     * @notice Contract lock strategy to lock only the caller is an adapter or extension.
     */
    function lockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = block.number;
        }
    }

    /**
     * @notice Contract lock strategy to release the lock only the caller is an adapter or extension.
     */
    function unlockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = 0;
        }
    }

    /**
     * CONFIGURATIONS
     */

    /**
     * @notice Sets a configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setConfiguration(bytes32 key, uint256 value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        mainConfiguration[key] = value;

        emit ConfigurationUpdated(key, value);
    }

    /**
     * @notice Sets an configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setAddressConfiguration(bytes32 key, address value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        addressConfiguration[key] = value;

        emit AddressConfigurationUpdated(key, value);
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getConfiguration(bytes32 key) external view returns (uint256) {
        return mainConfiguration[key];
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getAddressConfiguration(bytes32 key)
        external
        view
        returns (address)
    {
        return addressConfiguration[key];
    }

    /**
     * ADAPTERS
     */

    /**
     * @notice Replaces an adapter in the registry in a single step.
     * @notice It handles addition and removal of adapters as special cases.
     * @dev It removes the current adapter if the adapterId maps to an existing adapter address.
     * @dev It adds an adapter if the adapterAddress parameter is not zeroed.
     * @param adapterId The unique identifier of the adapter
     * @param adapterAddress The address of the new adapter or zero if it is a removal operation
     * @param acl The flags indicating the access control layer or permissions of the new adapter
     * @param keys The keys indicating the adapter configuration names.
     * @param values The values indicating the adapter configuration values.
     */
    function replaceAdapter(
        bytes32 adapterId,
        address adapterAddress,
        uint128 acl,
        bytes32[] calldata keys,
        uint256[] calldata values
    ) external hasAccess(this, AclFlag.REPLACE_ADAPTER) {
        require(adapterId != bytes32(0), 'adapterId must not be empty');

        address currentAdapterAddr = adapters[adapterId];
        if (currentAdapterAddr != address(0x0)) {
            delete inverseAdapters[currentAdapterAddr];
            delete adapters[adapterId];
            emit AdapterRemoved(adapterId);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 key = keys[i];
            uint256 value = values[i];
            mainConfiguration[key] = value;
            emit ConfigurationUpdated(key, value);
        }

        if (adapterAddress != address(0x0)) {
            require(
                inverseAdapters[adapterAddress].id == bytes32(0),
                'adapterAddress already in use'
            );
            adapters[adapterId] = adapterAddress;
            inverseAdapters[adapterAddress].id = adapterId;
            inverseAdapters[adapterAddress].acl = acl;
            emit AdapterAdded(adapterId, adapterAddress, acl);
        }
    }

    /**
     * @notice Looks up if there is an adapter of a given address
     * @return Whether or not the address is an adapter
     * @param adapterAddress The address to look up
     */
    function isAdapter(address adapterAddress) public view returns (bool) {
        return inverseAdapters[adapterAddress].id != bytes32(0);
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccess(address adapterAddress, AclFlag flag)
        external
        view
        returns (bool)
    {
        return
            DaoLibrary.getFlag(inverseAdapters[adapterAddress].acl, uint8(flag));
    }

    /**
     * @return The address of a given adapter ID
     * @param adapterId The ID to look up
     */
    function getAdapterAddress(bytes32 adapterId)
        external
        view
        returns (address)
    {
        require(adapters[adapterId] != address(0), 'adapter not found');
        return adapters[adapterId];
    }

    /**
     * EXTENSIONS
     */

    /**
     * @notice Adds a new extension to the registry
     * @param extensionId The unique identifier of the new extension
     * @param extension The address of the extension
     */
    // slither-disable-next-line reentrancy-events
    function addExtension(bytes32 extensionId, IExtension extension)
        external
        hasAccess(this, AclFlag.ADD_EXTENSION)
    {
        require(extensionId != bytes32(0), 'extension id must not be empty');
        require(
            extensions[extensionId] == address(0x0),
            'extensionId already in use'
        );
        require(
            !inverseExtensions[address(extension)].deleted,
            'extension can not be re-added'
        );
        extensions[extensionId] = address(extension);
        inverseExtensions[address(extension)].id = extensionId;
        emit ExtensionAdded(extensionId, address(extension));
    }

    // v1.0.6 signature
    function addExtension(
        bytes32,
        IExtension,
        address
    ) external {
        revert('not implemented');
    }

    /**
     * @notice Removes an adapter from the registry
     * @param extensionId The unique identifier of the extension
     */
    function removeExtension(bytes32 extensionId)
        external
        hasAccess(this, AclFlag.REMOVE_EXTENSION)
    {
        require(extensionId != bytes32(0), 'extensionId must not be empty');
        address extensionAddress = extensions[extensionId];
        require(extensionAddress != address(0x0), 'extensionId not registered');
        ExtensionEntry storage extEntry = inverseExtensions[extensionAddress];
        extEntry.deleted = true;
        //slither-disable-next-line mapping-deletion
        delete extensions[extensionId];
        emit ExtensionRemoved(extensionId);
    }

    /**
     * @notice Looks up if there is an extension of a given address
     * @return Whether or not the address is an extension
     * @param extensionAddr The address to look up
     */
    function isExtension(address extensionAddr) public view returns (bool) {
        return inverseExtensions[extensionAddr].id != bytes32(0);
    }

    /**
     * @notice It sets the ACL flags to an Adapter to make it possible to access specific functions of an Extension.
     */
    function setAclToExtensionForAdapter(
        address extensionAddress,
        address adapterAddress,
        uint256 acl
    ) external hasAccess(this, AclFlag.ADD_EXTENSION) {
        require(isAdapter(adapterAddress), 'not an adapter');
        require(isExtension(extensionAddress), 'not an extension');
        inverseExtensions[extensionAddress].acl[adapterAddress] = acl;
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccessToExtension(
        address adapterAddress,
        address extensionAddress,
        uint8 flag
    ) external view returns (bool) {
        return
            isAdapter(adapterAddress) &&
            DaoLibrary.getFlag(
                inverseExtensions[extensionAddress].acl[adapterAddress],
                uint8(flag)
            );
    }

    /**
     * @return The address of a given extension Id
     * @param extensionId The ID to look up
     */
    function getExtensionAddress(bytes32 extensionId)
        external
        view
        returns (address)
    {
        require(extensions[extensionId] != address(0), 'extension not found');
        return extensions[extensionId];
    }

    /**
     * PROPOSALS
     */

    /**
     * @notice Submit proposals to the DAO registry
     */
    function submitProposal(bytes32 proposalId)
        external
        hasAccess(this, AclFlag.SUBMIT_PROPOSAL)
    {
        require(proposalId != bytes32(0), 'invalid proposalId');
        require(
            !getProposalFlag(proposalId, ProposalFlag.EXISTS),
            'proposalId must be unique'
        );
        proposals[proposalId] = Proposal(msg.sender, 1); // 1 means that only the first flag is being set i.e. EXISTS
        emit SubmittedProposal(proposalId, 1);
    }

    /**
     * @notice Sponsor proposals that were submitted to the DAO registry
     * @dev adds SPONSORED to the proposal flag
     * @param proposalId The ID of the proposal to sponsor
     * @param sponsoringMember The member who is sponsoring the proposal
     */
    function sponsorProposal(
        bytes32 proposalId,
        address sponsoringMember,
        address votingAdapterAddr
    ) external onlyMember2(this, sponsoringMember) {
        // also checks if the flag was already set
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.SPONSORED
        );

        uint256 flags = proposal.flags;

        require(
            proposal.adapterAddress == msg.sender,
            'only the adapter that submitted the proposal can sponsor it'
        );

        require(
            !DaoLibrary.getFlag(flags, uint8(ProposalFlag.PROCESSED)),
            'proposal already processed'
        );
        votingAdapter[proposalId] = votingAdapterAddr;
        emit SponsoredProposal(proposalId, flags, votingAdapterAddr);
    }

    /**
     * @notice Mark a proposal as processed in the DAO registry
     * @param proposalId The ID of the proposal that is being processed
     */
    function processProposal(bytes32 proposalId) external {
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.PROCESSED
        );

        require(proposal.adapterAddress == msg.sender, 'err::adapter mismatch');
        uint256 flags = proposal.flags;

        emit ProcessedProposal(proposalId, flags);
    }

    /**
     * @notice Sets a flag of a proposal
     * @dev Reverts if the proposal is already processed
     * @param proposalId The ID of the proposal to be changed
     * @param flag The flag that will be set on the proposal
     */
    function _setProposalFlag(bytes32 proposalId, ProposalFlag flag)
        internal
        returns (Proposal storage)
    {
        Proposal storage proposal = proposals[proposalId];

        uint256 flags = proposal.flags;
        require(
            DaoLibrary.getFlag(flags, uint8(ProposalFlag.EXISTS)),
            'proposal does not exist for this dao'
        );

        require(
            proposal.adapterAddress == msg.sender,
            'invalid adapter try to set flag'
        );

        require(!DaoLibrary.getFlag(flags, uint8(flag)), 'flag already set');

        flags = DaoLibrary.setFlag(flags, uint8(flag), true);
        proposals[proposalId].flags = flags;

        return proposals[proposalId];
    }

    /**
     * @return Whether or not a flag is set for a given proposal
     * @param proposalId The proposal to check against flag
     * @param flag The flag to check in the proposal
     */
    function getProposalFlag(bytes32 proposalId, ProposalFlag flag)
        public
        view
        returns (bool)
    {
        return DaoLibrary.getFlag(proposals[proposalId].flags, uint8(flag));
    }

    /**
     * MEMBERS
     */

    /**
     * @notice Sets true for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function jailMember(address memberAddress)
        external
        hasAccess(this, AclFlag.JAIL_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        require(
            DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        member.flags = DaoLibrary.setFlag(
            member.flags,
            uint8(MemberFlag.JAILED),
            true
        );
    }

    /**
     * @notice Sets false for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function unjailMember(address memberAddress)
        external
        hasAccess(this, AclFlag.JAIL_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        require(
            DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        member.flags = DaoLibrary.setFlag(
            member.flags,
            uint8(MemberFlag.JAILED),
            false
        );
    }

    /**
     * @notice Checks if a given member address is not jailed.
     * @param memberAddress The address of the member to check the flag.
     */
    function notJailed(address memberAddress) external view returns (bool) {
        return
            !DaoLibrary.getFlag(
                members[memberAddress].flags,
                uint8(MemberFlag.JAILED)
            );
    }

    /**
     * @notice Registers a member address in the DAO if it is not registered or invalid.
     * @notice A potential new member is a member that holds no shares, and its registration still needs to be voted on.
     */
    function potentialNewMember(address memberAddress)
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        if (!DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
            require(
                memberAddressesByDelegatedKey[memberAddress] == address(0x0),
                'member address already taken as delegated key'
            );
            member.flags = DaoLibrary.setFlag(
                member.flags,
                uint8(MemberFlag.EXISTS),
                true
            );
            memberAddressesByDelegatedKey[memberAddress] = memberAddress;
            _members.push(memberAddress);
        }

        address bankAddress = extensions[DaoLibrary.BANK_EXT];
        if (bankAddress != address(0x0)) {
            BankExtension bank = BankExtension(bankAddress);
            if (bank.balanceOf(memberAddress, DaoLibrary.MEMBER_COUNT) == 0) {
                bank.addToBalance(
                    this,
                    memberAddress,
                    DaoLibrary.MEMBER_COUNT,
                    1
                );
            }
        }
    }
    
    function potentialNewMemberBatch(address[] calldata memberAddressArray)
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        for(uint256 i = 0;i<memberAddressArray.length;i++){
            require(memberAddressArray[i] != address(0x0), 'invalid member address');

            Member storage member = members[memberAddressArray[i]];
            if (!DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                require(
                    memberAddressesByDelegatedKey[memberAddressArray[i]] == address(0x0),
                    'member address already taken as delegated key'
                );
                member.flags = DaoLibrary.setFlag(
                    member.flags,
                    uint8(MemberFlag.EXISTS),
                    true
                );
                memberAddressesByDelegatedKey[memberAddressArray[i]] = memberAddressArray[i];
                _members.push(memberAddressArray[i]);
            }
            address bankAddress = extensions[DaoLibrary.BANK_EXT];
            if  (bankAddress != address(0x0)) {
                BankExtension bank = BankExtension(bankAddress);
                if (bank.balanceOf(memberAddressArray[i], DaoLibrary.MEMBER_COUNT) == 0) {
                    bank.addToBalance(
                        this,
                        memberAddressArray[i],
                        DaoLibrary.MEMBER_COUNT,
                        1
                    );
                }
            }
        }
    }
    /**
     * @return Whether or not a given address is a member of the DAO.
     * @dev it will resolve by delegate key, not member address.
     * @param addr The address to look up
     */
    function isMember(address addr) external view returns (bool) {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.EXISTS);
    }

    /**
     * @return Whether or not a flag is set for a given member
     * @param memberAddress The member to check against flag
     * @param flag The flag to check in the member
     */
    function getMemberFlag(address memberAddress, MemberFlag flag)
        public
        view
        returns (bool)
    {
        return DaoLibrary.getFlag(members[memberAddress].flags, uint8(flag));
    }

    /**
     * @notice Returns the number of members in the registry.
     */
    function getNbMembers() external view returns (uint256) {
        return _members.length;
    }

    /**
     * @notice Returns the member address for the given index.
     */
    function getMemberAddress(uint256 index) external view returns (address) {
        return _members[index];
    }

    /**
     * DELEGATE
     */

    /**
     * @notice Updates the delegate key of a member
     * @param memberAddr The member doing the delegation
     * @param newDelegateKey The member who is being delegated to
     */
    function updateDelegateKey(address memberAddr, address newDelegateKey)
        external
        hasAccess(this, AclFlag.UPDATE_DELEGATE_KEY)
    {
        require(newDelegateKey != address(0x0), 'newDelegateKey cannot be 0');

        // skip checks if member is setting the delegate key to their member address
        if (newDelegateKey != memberAddr) {
            require(
                // newDelegate must not be delegated to
                memberAddressesByDelegatedKey[newDelegateKey] == address(0x0),
                'cannot overwrite existing delegated keys'
            );
        } else {
            require(
                memberAddressesByDelegatedKey[memberAddr] == address(0x0),
                'address already taken as delegated key'
            );
        }

        Member storage member = members[memberAddr];
        require(
            DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        // Reset the delegation of the previous delegate
        memberAddressesByDelegatedKey[
            getCurrentDelegateKey(memberAddr)
        ] = address(0x0);

        memberAddressesByDelegatedKey[newDelegateKey] = memberAddr;

        _createNewDelegateCheckpoint(memberAddr, newDelegateKey);
        emit UpdateDelegateKey(memberAddr, newDelegateKey);
    }

    /**
     * @param checkAddr The address to check for a delegate
     * @return the delegated address or the checked address if it is not a delegate
     */
    function getAddressIfDelegated(address checkAddr)
        external
        view
        returns (address)
    {
        address delegatedKey = memberAddressesByDelegatedKey[checkAddr];
        return delegatedKey == address(0x0) ? checkAddr : delegatedKey;
    }

    /**
     * @param memberAddr The member whose delegate will be returned
     * @return the delegate key at the current time for a member
     */
    function getCurrentDelegateKey(address memberAddr)
        public
        view
        returns (address)
    {
        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        return
            nCheckpoints > 0
                ? _checkpoints[memberAddr][nCheckpoints - 1].delegateKey
                : memberAddr;
    }

    /**
     * @param memberAddr The member address to look up
     * @return The delegate key address for memberAddr at the second last checkpoint number
     */
    function getPreviousDelegateKey(address memberAddr)
        external
        view
        returns (address)
    {
        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        return
            nCheckpoints > 1
                ? _checkpoints[memberAddr][nCheckpoints - 2].delegateKey
                : memberAddr;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param memberAddr The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The delegate key of the member
     */
    function getPriorDelegateKey(address memberAddr, uint256 blockNumber)
        external
        view
        returns (address)
    {
        require(blockNumber < block.number, 'getPriorDelegateKey: NYD');

        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        if (nCheckpoints == 0) {
            return memberAddr;
        }

        // First check most recent balance
        if (
            _checkpoints[memberAddr][nCheckpoints - 1].fromBlock <= blockNumber
        ) {
            return _checkpoints[memberAddr][nCheckpoints - 1].delegateKey;
        }

        // Next check implicit zero balance
        if (_checkpoints[memberAddr][0].fromBlock > blockNumber) {
            return memberAddr;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            DelegateCheckpoint memory cp = _checkpoints[memberAddr][center];
            if (cp.fromBlock == blockNumber) {
                return cp.delegateKey;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return _checkpoints[memberAddr][lower].delegateKey;
    }

    /**
     * @notice Creates a new delegate checkpoint of a certain member
     * @param member The member whose delegate checkpoints will be added to
     * @param newDelegateKey The delegate key that will be written into the new checkpoint
     */
    function _createNewDelegateCheckpoint(
        address member,
        address newDelegateKey
    ) internal {
        uint32 nCheckpoints = _numCheckpoints[member];
        // The only condition that we should allow the deletegaKey upgrade
        // is when the block.number exactly matches the fromBlock value.
        // Anything different from that should generate a new checkpoint.
        if (
            //slither-disable-next-line incorrect-equality
            nCheckpoints > 0 &&
            _checkpoints[member][nCheckpoints - 1].fromBlock == block.number
        ) {
            _checkpoints[member][nCheckpoints - 1].delegateKey = newDelegateKey;
        } else {
            _checkpoints[member][nCheckpoints] = DelegateCheckpoint(
                uint96(block.number),
                newDelegateKey
            );
            _numCheckpoints[member] = nCheckpoints + 1;
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "./interfaces/IManagerAdapter.sol";
import "../core/DaoRegistry.sol";
import "../adapters/interfaces/IVotingAdapter.sol";
import "../adapters/interfaces/IManagerAdapter.sol";
import "../modifiers/AdapterGuard.sol";
import "../modifiers/Reimbursable.sol";
import "../libraries/DaoLibrary.sol";
import "../libraries/VotingAdapterLibrary.sol";

contract ManagerAdapter is IManagerAdapter, AdapterGuard, Reimbursable {

    mapping(address => mapping(bytes32 => ManagerProposal)) public managerProposal;

    mapping(address => mapping(bytes32 => ManagerConfigurationProposal)) public managerConfigurationProposal;

    //EVENT
    event SubmitManagerProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId
    );

    event SubmitManagerConfigurationProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId
    );

    event ProcessManagerProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId
    );

    event ProcessManagerConfigurationProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId
    );

    //SUBMIT
    function submitManagerProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        ManagerProposal calldata proposal
    ) external override reimbursable(dao) {
        string memory origin = "ManagerAdapter.submitManagerProposal";
        require(
            proposal.keys.length == proposal.values.length,
            "must be an equal number of config keys and values"
        );
        require(
            proposal.extensionAddresses.length == proposal.extensionAclFlags.length,
            "must be an equal number of extension addresses and acl"
        );
        require(
            DaoLibrary.isNotReservedAddress(proposal.adapterOrExtensionAddr),
            "address is reserved"
        );
        managerProposal[address(dao)][proposalId] = proposal;
        managerProposal[address(dao)][proposalId].status = Foundance.ProposalStatus.NOT_STARTED;
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitManagerProposalEvent(address(dao), msg.sender, data, proposalId);
    }
    
    function submitManagerConfigurationProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Configuration[] calldata _configuration
    ) external override reimbursable(dao) {
        string memory origin= "ManagerAdapter.submitManagerConfigurationProposal";
        require(
            _configuration.length > 0,
            "missing configs"
        );
        Configuration[] storage configuration = managerConfigurationProposal[address(dao)][proposalId].configuration;
        for (uint256 i = 0; i < _configuration.length; i++) {
            Configuration memory config = _configuration[i];
            configuration.push(
                Configuration({
                    key: config.key,
                    configType: config.configType,
                    numericValue: config.numericValue,
                    addressValue: config.addressValue
                })
            );
        }
        managerConfigurationProposal[address(dao)][proposalId].status = Foundance.ProposalStatus.NOT_STARTED;
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitManagerConfigurationProposalEvent(address(dao), msg.sender, data, proposalId);
    }

    //PROCESS_INTERNAL
    function _replaceExtension(
        DaoRegistry dao, 
        ManagerProposal memory proposal
    )
        internal
    {
        if (dao.extensions(proposal.adapterOrExtensionId) != address(0x0)) {
            dao.removeExtension(proposal.adapterOrExtensionId);
        }

        if (proposal.adapterOrExtensionAddr != address(0x0)) {
            dao.addExtension(
                proposal.adapterOrExtensionId,
                IExtension(proposal.adapterOrExtensionAddr)
            );
        }
    }

    function _grantExtensionAccess(
        DaoRegistry dao,
        ManagerProposal memory proposal
    ) 
        internal 
    {
        for (uint256 i = 0; i < proposal.extensionAclFlags.length; i++) {
            dao.setAclToExtensionForAdapter(
                proposal.extensionAddresses[i],
                proposal.adapterOrExtensionAddr,
                proposal.extensionAclFlags[i]
            );
        }
    }

    function _saveDaoConfigurations(
        DaoRegistry dao, 
        Configuration[] memory _configuration
    )
        internal
    {
        for (uint256 i = 0; i < _configuration.length; i++) {
            Configuration memory config = _configuration[i];
            if (ConfigType.NUMERIC == config.configType) {
                dao.setConfiguration(config.key, config.numericValue);
            } else if (ConfigType.ADDRESS == config.configType) {
                dao.setAddressConfiguration(config.key, config.addressValue);
            }
        }
    }

    //PROCESS
    function processManagerProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        ManagerProposal memory proposal = managerProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "managerAdpt::proposal already completed or in progress"
        );  
        proposal.status = VotingAdapterLibrary._processProposal(dao, proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            if (proposal.updateType == UpdateType.ADAPTER) {
                dao.replaceAdapter(
                    proposal.adapterOrExtensionId,
                    proposal.adapterOrExtensionAddr,
                    proposal.flags,
                    proposal.keys,
                    proposal.values
                );
            } else if (proposal.updateType == UpdateType.EXTENSION) {
                _replaceExtension(dao, proposal);
            } else {
                revert("unknown update type");
            }
            _grantExtensionAccess(dao, proposal);
            _saveDaoConfigurations(dao, proposal.configuration);
            proposal.status == Foundance.ProposalStatus.DONE;
        }
        emit ProcessManagerProposalEvent(address(dao), msg.sender, proposalId);
    }

    function processManagerConfigurationProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        ManagerConfigurationProposal memory proposal = managerConfigurationProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "managerAdpt::proposal already completed or in progress"
        );  
        proposal.status = VotingAdapterLibrary._processProposal(dao, proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            _saveDaoConfigurations(dao, proposal.configuration);
            proposal.status == Foundance.ProposalStatus.DONE;
        }
        emit ProcessManagerConfigurationProposalEvent(address(dao), msg.sender, proposalId);
    }

    /**
     * @notice Allows the member/advisor to update their delegate key
     * @param dao The DAO address.
     * @param delegateKey the new delegate key.
     */
    function updateDelegateKey(DaoRegistry dao, address delegateKey)
        external
        reentrancyGuard(dao)
    {
        address dk = dao.getCurrentDelegateKey(msg.sender);
        if (dk != msg.sender && dao.isMember(dk)) {
            dao.updateDelegateKey(msg.sender, delegateKey);
        } else {
            require(dao.isMember(msg.sender), "only member");
            dao.updateDelegateKey(
                DaoLibrary.msgSender(dao, msg.sender),
                delegateKey
            );
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import { Foundance } from "../libraries/Foundance.sol";
import "./interfaces/IVotingAdapter.sol";
import "../core/DaoRegistry.sol";
import "../extensions/BankExtension.sol";
import "../modifiers/MemberGuard.sol";
import "../modifiers/AdapterGuard.sol";
import "../modifiers/Reimbursable.sol";
import "../libraries/DaoLibrary.sol";
import "../libraries/GovernanceLibrary.sol";

contract VotingAdapter is
  IVotingAdapter,
  MemberGuard,
  AdapterGuard,
  Reimbursable
{

    string public constant ADAPTER_NAME = "VotingAdapter";

    struct Voting {
        uint256 nbYes;
        uint256 nbNo;
        uint256 nbMembers;
        uint256 nbTokens;
        uint256 startingTime;
        uint256 graceStartingTime;
        uint256 disputeStartingTime;
        uint256 blockNumber;
        bytes32 proposalId;
        bytes data;
        string origin;
        address submittedBy;
        Foundance.VotingType votingType;
        Foundance.VotingState votingState;
    }

    mapping(address => Foundance.VotingConfig) public votingConfig;

    mapping(address => mapping(string => Foundance.VotingConfig)) public votingFunctionConfig;//TODO

    mapping(address => mapping(bytes32 => uint256)) public votingIndex;

    mapping(address => Voting[]) public voting;

    mapping(address => mapping(bytes32 => mapping(address => uint256))) public votingVotes;
    

    //EVENT
    event StartNewVotingForProposalEvent(
        address _address, 
        bytes32 _proposalId, 
        bytes data, 
        string origin
    );

    event SubmitVoteEvent(
        address _address
    );


    function getAdapterName() external pure override returns (string memory) {
        return ADAPTER_NAME;
    }

    function configureDao(
        DaoRegistry dao,
        Foundance.VotingConfig memory _votingConfig
    ) external onlyAdapter(dao) {
        if(_votingConfig.passRateToken > 100){
            _votingConfig.passRateToken = 100;
        }
        if(_votingConfig.supportRequired > 100){
            _votingConfig.supportRequired = 100;
        }
        votingConfig[address(dao)] = _votingConfig;
    }

    function getSenderAddress(
        DaoRegistry,
        address,
        bytes memory,
        address sender
    ) external pure override returns (address) {
        return sender;
    }

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        string calldata origin
    ) external override onlyAdapter(dao) {
        uint length = voting[address(dao)].length;
        votingIndex[address(dao)][proposalId]=length;
        Voting memory vote;
        vote.startingTime = block.timestamp;
        vote.blockNumber = block.number;
        vote.votingType = votingConfig[address(dao)].votingType;
        vote.origin = origin;
        vote.votingState = Foundance.VotingState.IN_PROGRESS;
        vote.proposalId = proposalId;
        vote.data = data;
        vote.submittedBy = tx.origin;
        voting[address(dao)].push(vote);
        emit StartNewVotingForProposalEvent(msg.sender, proposalId, data, origin);
    }

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        string calldata origin,
        Foundance.VotingType _votingType
    ) external onlyAdapter(dao) {
        uint length = voting[address(dao)].length;
        votingIndex[address(dao)][proposalId]=length;
        Voting memory vote;
        vote.startingTime = block.timestamp;
        vote.blockNumber = block.number;
        vote.votingType = _votingType;
        vote.origin = origin;
        vote.votingState = Foundance.VotingState.IN_PROGRESS;
        vote.proposalId = proposalId;
        vote.data = data;
        vote.submittedBy = tx.origin;
        voting[address(dao)].push(vote);
        emit StartNewVotingForProposalEvent(msg.sender, proposalId, data, origin);
    }

    function submitVote(
        DaoRegistry dao,
        bytes32 proposalId,
        uint256 voteValue,
        uint256 weightedVoteValue
    ) external onlyMember(dao) reimbursable(dao) {
        require(
            dao.getProposalFlag(proposalId, DaoRegistry.ProposalFlag.SPONSORED),
            "the proposal has not been sponsored yet"
        );
        require(
            !dao.getProposalFlag(
                proposalId,
                DaoRegistry.ProposalFlag.PROCESSED
            ),
            "the proposal has already been processed"
        );
        require(
            voteValue < 3 && voteValue > 0,
            "only yes (1) and no (2) are possible values"
        );
        Voting storage vote = voting[address(dao)][votingIndex[address(dao)][proposalId]];
        Foundance.VotingConfig memory _votingConfig = votingConfig[address(dao)];
        require(
            vote.startingTime > 0,
            "this proposalId has no vote going on at the moment"
        );
        require(
            block.timestamp <
                vote.startingTime + _votingConfig.votingPeriod,
            "vote has already ended"
        );
        address memberAddr = DaoLibrary.msgSender(dao, msg.sender);
        require(votingVotes[address(dao)][proposalId][memberAddr] == 0, "member has already voted");
        uint256 tokenAmount = GovernanceLibrary.getVotingWeight(
            dao,
            memberAddr,
            proposalId,
            vote.blockNumber
        );
        uint256 votingWeight = 0;
        if (tokenAmount == 0) revert("vote not allowed");
        vote.nbMembers += 1;
        vote.nbTokens += tokenAmount;
        votingVotes[address(dao)][proposalId][memberAddr] = voteValue;
        if(vote.votingType == Foundance.VotingType.PROPORTIONAL){
            votingWeight = tokenAmount; 
        }else if(vote.votingType == Foundance.VotingType.QUADRATIC){
            votingWeight = DaoLibrary.sqrt(tokenAmount);
        }else if(vote.votingType == Foundance.VotingType.OPTIMISTIC){
            votingWeight = tokenAmount; 
        }else if(vote.votingType == Foundance.VotingType.COOPERATIVE){
            votingWeight = 1;
        }
        if(vote.votingType == Foundance.VotingType.WEIGHTED){
            votingWeight = tokenAmount; 
            weightedVoteValue = weightedVoteValue>100?100:weightedVoteValue;
            uint256 weightedVotingWeight = (votingWeight*weightedVoteValue) / 100;
            uint256 weightedVotingMinorityWeight = votingWeight-weightedVotingWeight;
            if(voteValue == 1){
                vote.nbYes = vote.nbYes + weightedVotingWeight;
                vote.nbNo = vote.nbNo + weightedVotingMinorityWeight;
            }else{
                vote.nbYes = vote.nbYes + weightedVotingMinorityWeight;
                vote.nbNo = vote.nbNo + weightedVotingWeight;
            }
        } else if (voteValue == 1) {
            vote.nbYes = vote.nbYes + votingWeight;
        } else if (voteValue == 2) {
            vote.nbNo = vote.nbNo + votingWeight;
        }
        emit SubmitVoteEvent(msg.sender);
    }

    function voteResult(DaoRegistry dao, bytes32 proposalId)
        external
        override
        returns (Foundance.VotingState state)
    {
        Voting storage vote = voting[address(dao)][votingIndex[address(dao)][proposalId]];
        Foundance.VotingConfig memory _votingConfig = votingConfig[address(dao)];
        if (vote.startingTime == 0) {
            vote.votingState = Foundance.VotingState.NOT_STARTED;
            return vote.votingState;
        }
        if (
            block.timestamp <
            vote.startingTime + _votingConfig.votingPeriod
        ) {
            vote.votingState = Foundance.VotingState.IN_PROGRESS;
            return vote.votingState;
        }
        if (
            block.timestamp <
            vote.startingTime +
                _votingConfig.votingPeriod +
                _votingConfig.gracePeriod
        ) {
            vote.votingState = Foundance.VotingState.GRACE_PERIOD;
            return vote.votingState;
        }
        if(vote.votingType == Foundance.VotingType.OPTIMISTIC){
            if (vote.nbYes >= vote.nbNo) {
                vote.votingState = Foundance.VotingState.PASS;
                return vote.votingState;
            } else if (vote.nbYes < vote.nbNo) {
                vote.votingState = Foundance.VotingState.NOT_PASS;
                return vote.votingState;
            }
            vote.votingState = Foundance.VotingState.PASS;
            return vote.votingState;
        }else{
            BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
            uint256 totalUnitTokens = DaoLibrary.totalUnitTokens(bank);
            if( 
                _votingConfig.passRateMember < vote.nbMembers || 
                (_votingConfig.passRateToken*totalUnitTokens) / 100  < vote.nbTokens || 
                (_votingConfig.supportRequired*totalUnitTokens) / 100 < vote.nbTokens   
            ) {
                vote.votingState = Foundance.VotingState.NOT_PASS;
                return vote.votingState;
            }
            if (vote.nbYes > vote.nbNo) {
                vote.votingState = Foundance.VotingState.PASS;
                return vote.votingState;
            } else if (vote.nbYes < vote.nbNo) {
                vote.votingState = Foundance.VotingState.NOT_PASS;
                return vote.votingState;
            } else {
                vote.votingState = Foundance.VotingState.TIE;
                return vote.votingState;
            }
        }
    }

    function getVoting(
        address dao
    ) external view returns (Voting[] memory) {
        return voting[address(dao)];
    }

    function getVotingVotes(
        address dao,
        bytes32 proposalId,
        address member
    ) external view returns (uint256 votes) {
        return votingVotes[address(dao)][proposalId][member];
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import "../core/DaoRegistry.sol";
import "../adapters/VotingAdapter.sol";
import "../extensions/BankExtension.sol";
import "../extensions/MemberExtension.sol";
import "../libraries/VotingAdapterLibrary.sol";
import "../libraries/DaoLibrary.sol";
import "../modifiers/Reimbursable.sol";
import "../modifiers/AdapterGuard.sol";
import "../modifiers/MemberGuard.sol";
import "./interfaces/IMemberAdapter.sol";
import "./interfaces/IVotingAdapter.sol";

contract MemberAdapter is IMemberAdapter, Reimbursable, MemberGuard, AdapterGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    struct MemberProposal {
        Foundance.ProposalStatus status;
        Foundance.MemberConfig memberConfig;
    }

    struct MemberRemoveProposal {
        Foundance.ProposalStatus status;
        address memberAddress;
    }

    struct MemberSetupProposal {
        Foundance.ProposalStatus status;
        Foundance.MemberConfig memberConfig;
        Foundance.DynamicEquityMemberConfig dynamicEquityMemberConfig;
        Foundance.VestedEquityMemberConfig vestedEquityMemberConfig;
        Foundance.CommunityEquityMemberConfig communityEquityMemberConfig;
    }

    struct MemberAgreementProposal {
        Foundance.ProposalStatus status;
        Foundance.FactoryMemberConfig[] factoryMemberConfigArray;
        Foundance.VotingConfig votingConfig;
        Foundance.EpochConfig epochConfig;
        Foundance.DynamicEquityConfig dynamicEquityConfig;
        Foundance.VestedEquityConfig vestedEquityConfig;
        Foundance.CommunityEquityConfig communityEquityConfig;
    }

    mapping(address => mapping(bytes32 => MemberProposal)) public setMemberProposal;

    mapping(address => mapping(bytes32 => MemberSetupProposal)) public setMemberSetupProposal;

    mapping(address => mapping(bytes32 => MemberAgreementProposal)) public setMemberAgreementProposal;

    mapping(address => mapping(bytes32 => MemberRemoveProposal)) public removeMemberProposal;

    mapping(address => mapping(bytes32 => MemberRemoveProposal)) public removeMemberBadLeaverProposal;

    mapping(address => mapping(bytes32 => MemberRemoveProposal)) public removeMemberResigneeProposal;

    //EVENT
    event SubmitSetMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId, 
        Foundance.MemberConfig _memberConfig
    );
        
    event SubmitSetMemberSetupProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId, 
        Foundance.MemberConfig _memberConfig,
        Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig, 
        Foundance.VestedEquityMemberConfig _vestedEquityMemberConfig, 
        Foundance.CommunityEquityMemberConfig _communityEquityMemberConfig
    );

    event SubmitSetMemberAgreementProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId
    );
          
    event SubmitRemoveMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId, 
        address _memberAddress
    );
        
    event SubmitRemoveMemberBadLeaverProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId, 
        address _memberAddress
    );
        
    event SubmitRemoveMemberResigneeProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId, 
        address _memberAddress
    );

    event ProcessSetMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId, 
        Foundance.MemberConfig _memberConfig
    );

    event ProcessSetMemberSetupProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId, 
        Foundance.MemberConfig _memberConfig,
        Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig, 
        Foundance.VestedEquityMemberConfig _vestedEquityMemberConfig, 
        Foundance.CommunityEquityMemberConfig _communityEquityMemberConfig
    );

    event ProcessSetMemberAgreementProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId
    );

    event ProcessRemoveMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId, 
        address _memberAddress, 
        bytes32 _newProposalId
    );

    event ProcessRemoveMemberBadLeaverProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId, 
        address _memberAddress, 
        bool goodLeaver
    );

    event ProcessRemoveMemberResigneeProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId, 
        address _memberAddress, 
        bool goodLeaver
    );

    event ActMemberResignEvent(
        address _daoAddress, address _senderAddress, bytes _data, 
        address _memberAddress
    );

    event SetMemberEvent(
        address _daoAddress, 
        Foundance.MemberConfig _memberConfig
    );

    event RemoveMemberEvent(
        address _daoAddress, address _senderAddress
    );

    //SUBMIT_INTERNAL
    function _submitRemoveMemberBadLeaverProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        address _memberAddress
    ) internal {
        string memory origin = "MemberAdapter._submitRemoveMemberBadLeaverProposal";
        removeMemberBadLeaverProposal[address(dao)][proposalId] = MemberRemoveProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin, Foundance.VotingType.OPTIMISTIC);
        emit SubmitRemoveMemberBadLeaverProposalEvent(address(dao),msg.sender, data, proposalId, _memberAddress);
    }

    function _submitRemoveMemberResigneeProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        address _memberAddress
    ) internal {
        string memory origin = "MemberAdapter._submitRemoveMemberResigneeProposal";
        removeMemberResigneeProposal[address(dao)][proposalId] = MemberRemoveProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin, Foundance.VotingType.OPTIMISTIC);
        emit SubmitRemoveMemberResigneeProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    }

    //SUBMIT
    function submitSetMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        Foundance.MemberConfig memory _memberConfig
    ) external override reimbursable(dao) {
        string memory origin = "MemberAdapter.submitSetMemberProposal";
        require(
            DaoLibrary.isNotReservedAddress(_memberConfig.memberAddress),
            "MemberAdpt::applicant is reserved address"
        );
        setMemberProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberConfig
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitSetMemberProposalEvent(address(dao), msg.sender, data, proposalId, _memberConfig);
    }

    function submitSetMemberSetupProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        Foundance.MemberConfig memory _memberConfig,
        Foundance.DynamicEquityMemberConfig memory _dynamicEquityMemberConfig,
        Foundance.VestedEquityMemberConfig memory _vestedEquityMemberConfig,
        Foundance.CommunityEquityMemberConfig memory _communityEquityMemberConfig
    ) external override reimbursable(dao) {
        string memory origin = "MemberAdapter.submitSetMemberSetupProposal";
        require(
            DaoLibrary.isNotReservedAddress(_memberConfig.memberAddress),
            "MemberAdpt::applicant is reserved address"
        );
        setMemberSetupProposal[address(dao)][proposalId] = MemberSetupProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberConfig,
            _dynamicEquityMemberConfig,
            _vestedEquityMemberConfig,
            _communityEquityMemberConfig
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitSetMemberSetupProposalEvent(
            address(dao), msg.sender, data, proposalId, _memberConfig, _dynamicEquityMemberConfig, _vestedEquityMemberConfig, _communityEquityMemberConfig);
    }

    function submitSetMemberAgreementProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        Foundance.FactoryMemberConfig[] memory _factoryMemberConfigArray,
        Foundance.VotingConfig memory _votingConfig,
        Foundance.EpochConfig memory _epochConfig,
        Foundance.DynamicEquityConfig memory _dynamicEquityConfig,
        Foundance.VestedEquityConfig memory _vestedEquityConfig,
        Foundance.CommunityEquityConfig memory _communityEquityConfig
    ) external reimbursable(dao) {
        Foundance.FactoryMemberConfig[] storage factoryMemberConfigArray = setMemberAgreementProposal[address(dao)][proposalId].factoryMemberConfigArray;
        for(uint i = 0; i <  _factoryMemberConfigArray.length; i++){
            require(
                DaoLibrary.isNotReservedAddress(_factoryMemberConfigArray[i].memberAddress),
                "MemberAdpt::applicant is reserved address"
            );
            factoryMemberConfigArray.push(_factoryMemberConfigArray[i]);
        }
        MemberAgreementProposal storage proposal = setMemberAgreementProposal[address(dao)][proposalId];
        proposal.status = Foundance.ProposalStatus.NOT_STARTED;
        proposal.votingConfig = _votingConfig;
        proposal.epochConfig = _epochConfig;
        proposal.dynamicEquityConfig = _dynamicEquityConfig;
        proposal.vestedEquityConfig = _vestedEquityConfig;
        proposal.communityEquityConfig = _communityEquityConfig;
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, "MemberAdapter.submitSetMemberAgreementProposal");
        emit SubmitSetMemberAgreementProposalEvent(address(dao), msg.sender, data, proposalId);
    }

    function submitRemoveMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        address _memberAddress
    ) external override reimbursable(dao) {
        string memory origin = "MemberAdapter.submitRemoveMemberProposal";
        require(dao.isMember(_memberAddress), "_memberAddress not a member");
        removeMemberProposal[address(dao)][proposalId] = MemberRemoveProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitRemoveMemberProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    }

    //PROCESS_INTERNAL
    function _processRemoveMemberToken(
        DaoRegistry dao,
        address _memberAddress
    ) internal {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        uint256 unitsToBurn = bank.balanceOf(_memberAddress, DaoLibrary.UNITS);
        bank.subtractFromBalance(dao, _memberAddress, DaoLibrary.UNITS, unitsToBurn);
    }

    //PROCESS
    function processSetMemberProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberProposal storage proposal = setMemberProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = VotingAdapterLibrary._processProposal(dao, proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            MemberExtension member = MemberExtension(dao.getExtensionAddress(DaoLibrary.MEMBER_EXT));
            member.setMember(
                dao,
                proposal.memberConfig
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.memberConfig);
        }
    }

    function processSetMemberSetupProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberSetupProposal storage proposal = setMemberSetupProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = VotingAdapterLibrary._processProposal(dao, proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            MemberExtension member = MemberExtension(dao.getExtensionAddress(DaoLibrary.MEMBER_EXT));
            member.setMember(
                dao,
                proposal.memberConfig
            );
            member.setMemberSetup(
                dao, 
                proposal.dynamicEquityMemberConfig,
                proposal.vestedEquityMemberConfig,
                proposal.communityEquityMemberConfig
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetMemberSetupProposalEvent(
                address(dao), msg.sender, proposalId, proposal.memberConfig, proposal.dynamicEquityMemberConfig, proposal.vestedEquityMemberConfig, proposal.communityEquityMemberConfig);
        }
    }

    function processSetMemberAgreementProposal(DaoRegistry dao, bytes32 proposalId)
        external
        reimbursable(dao)
    {
        MemberAgreementProposal storage proposal = setMemberAgreementProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = VotingAdapterLibrary._processProposal(dao, proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            VotingAdapter voting = VotingAdapter(dao.getAdapterAddress(DaoLibrary.VOTING_ADPT));
            voting.configureDao(dao, proposal.votingConfig);
            MemberExtension member = MemberExtension(dao.getExtensionAddress(DaoLibrary.MEMBER_EXT));
            member.setMemberEnvironment(dao,proposal.dynamicEquityConfig,proposal.vestedEquityConfig,proposal.communityEquityConfig,proposal.epochConfig);
            for(uint256 i=0;i<proposal.factoryMemberConfigArray.length;i++){
                Foundance.FactoryMemberConfig memory factoryMemberConfig = proposal.factoryMemberConfigArray[i];
                member.setMember(
                    dao,
                    factoryMemberConfig.memberConfig
                );
                member.setMemberSetup(
                    dao, 
                    factoryMemberConfig.dynamicEquityMemberConfig,
                    factoryMemberConfig.vestedEquityMemberConfig,
                    factoryMemberConfig.communityEquityMemberConfig
                );
            }
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetMemberAgreementProposalEvent(
                address(dao), msg.sender, proposalId
            );
        }
    }

    function processRemoveMemberProposal(DaoRegistry dao, bytes32 proposalId, bytes calldata data, bytes32 newProposalId)
        external
        override
        reimbursable(dao)
    {
        MemberRemoveProposal storage proposal = removeMemberProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = VotingAdapterLibrary._processProposal(dao, proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            MemberExtension member = MemberExtension(
                dao.getExtensionAddress(DaoLibrary.MEMBER_EXT)
            );
            dao.jailMember(proposal.memberAddress);
            member.removeMemberSetup(dao, proposal.memberAddress);
            _submitRemoveMemberBadLeaverProposal(dao, newProposalId, data, proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        }
        emit ProcessRemoveMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress, newProposalId);
    }

    function processRemoveMemberBadLeaverProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberRemoveProposal storage proposal = removeMemberBadLeaverProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = VotingAdapterLibrary._processProposal(dao, proposalId);
        bool goodLeaver = false;
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            goodLeaver = true;
            dao.unjailMember(proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        } else if (proposal.status == Foundance.ProposalStatus.FAILED){
            _processRemoveMemberToken(dao,proposal.memberAddress);
            MemberExtension member = MemberExtension(dao.getExtensionAddress(DaoLibrary.MEMBER_EXT));
            member.removeMember(
                dao,
                proposal.memberAddress
            );
            dao.unjailMember(proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        }
        emit ProcessRemoveMemberBadLeaverProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress, goodLeaver);
    }

     function processRemoveMemberResigneeProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberRemoveProposal storage proposal = removeMemberResigneeProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = VotingAdapterLibrary._processProposal(dao, proposalId);
        bool goodLeaver = false;
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            goodLeaver = true;
            dao.unjailMember(proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        } else if (proposal.status == Foundance.ProposalStatus.FAILED){
            MemberExtension member = MemberExtension(dao.getExtensionAddress(DaoLibrary.MEMBER_EXT));
            member.removeMember(
                dao,
                proposal.memberAddress
            );
            dao.unjailMember(proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        }
        emit ProcessRemoveMemberResigneeProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress, goodLeaver);
    }

    //ACT
    function actMemberResign(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        address _memberAddress
    ) external override reimbursable(dao) {
        require(
            _memberAddress == msg.sender,
            "memberAdpt::_memberAddress==msg.sender required"
        );
        require(
            dao.isMember(_memberAddress),
            "memberAdpt::_memberAddress not a member"
        );
        MemberExtension member = MemberExtension(
            dao.getExtensionAddress(DaoLibrary.MEMBER_EXT)
        );
        dao.jailMember(_memberAddress);
        member.removeMemberSetup(dao, _memberAddress);
        Foundance.MemberConfig memory memberConfig = member.getMemberConfig(_memberAddress);
        if(memberConfig.initialPeriod<block.timestamp){
            _submitRemoveMemberResigneeProposal(dao,proposalId, data, _memberAddress);
        }else{
            _submitRemoveMemberBadLeaverProposal(dao,proposalId, data, _memberAddress);
        }
        emit ActMemberResignEvent(address(dao), msg.sender, data, _memberAddress);
    }

}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import "./interfaces/IVotingAdapter.sol";
import "./interfaces/IDynamicEquityAdapter.sol";
import "../core/DaoRegistry.sol";
import "../extensions/BankExtension.sol";
import "../extensions/DynamicEquityExtension.sol";
import "../modifiers/AdapterGuard.sol";
import "../modifiers/Reimbursable.sol";
import "../libraries/VotingAdapterLibrary.sol";
import "../libraries/GovernanceLibrary.sol";
import "../libraries/DaoLibrary.sol";



contract DynamicEquityAdapter is IDynamicEquity, AdapterGuard, Reimbursable {

    struct DynamicEquityProposal {
        Foundance.ProposalStatus status;
        Foundance.DynamicEquityConfig dynamicEquityConfig;
        Foundance.EpochConfig epochConfig;
    }

    struct DynamicEquityMemberProposal {
        Foundance.ProposalStatus status;
        Foundance.DynamicEquityMemberConfig dynamicEquityMemberConfig;
    }

    struct DynamicEquityEpochProposal {
        Foundance.ProposalStatus status;
        uint256 lastEpoch; 
    }

    struct MemberProposal {
        Foundance.ProposalStatus status;
        address memberAddress;
    }
    
     struct MemberValueProposal {
        Foundance.ProposalStatus status;
        address memberAddress;
        uint256 value; 
    }

    mapping(address => mapping(bytes32 => DynamicEquityProposal)) public setDynamicEquityProposal;

    mapping(address => mapping(bytes32 => DynamicEquityEpochProposal)) public setDynamicEquityEpochProposal;

    mapping(address => mapping(bytes32 => DynamicEquityMemberProposal)) public setDynamicEquityMemberProposal;

    mapping(address => mapping(bytes32 => MemberValueProposal)) public setDynamicEquityMemberSuspendProposal;

    mapping(address => mapping(bytes32 => DynamicEquityMemberProposal)) public setDynamicEquityMemberEpochProposal;

    mapping(address => mapping(bytes32 => MemberValueProposal)) public setDynamicEquityMemberEpochExpenseProposal;

    mapping(address => mapping(bytes32 => MemberProposal)) public removeDynamicEquityMemberProposal;

    mapping(address => mapping(bytes32 => MemberProposal)) public removeDynamicEquityMemberEpochProposal;

    //EVENT
    event SubmitSetDynamicEquityProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        Foundance.DynamicEquityConfig _dynamicEquityConfig, 
        Foundance.EpochConfig _epochConfig
    );

    event SubmitSetDynamicEquityEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        uint _unixTimestampInS
    );

    event SubmitSetDynamicEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig
    );

    event SubmitSetDynamicEquityMemberSuspendProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        address _memberAddress, uint256 _suspendUntil
    );

    event SubmitSetDynamicEquityMemberEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig
    );

    event SubmitSetDynamicEquityMemberEpochExpenseProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        address _memberAddress, 
        uint256 _requestAmount
    );

    event SubmitRemoveDynamicEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        address _memberAddress
    );

    event SubmitRemoveDynamicEquityMemberEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        address _memberAddress
    );
  
    event ProcessSetDynamicEquityProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        Foundance.DynamicEquityConfig _dynamicEquityConfig, 
        Foundance.EpochConfig _epochConfig
    );

    event ProcessSetDynamicEquityEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        uint _unixTimestampInS
    );

    event ProcessSetDynamicEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig
    );

    event ProcessSetDynamicEquityMemberSuspendProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        address _memberAddress, 
        uint256 _suspendUntil
    );

    event ProcessSetDynamicEquityMemberEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig
    );

    event ProcessSetDynamicEquityMemberEpochExpenseProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        address _memberAddress,
        uint256 _requestAmount,
        uint256 _expenseAmount
    );

    event ProcessRemoveDynamicEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        address _memberAddress
    );

    event ProcessRemoveDynamicEquityMemberEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        address _memberAddress
    );

    event ActDynamicEquityMemberEpochDistributedEvent(
        address _daoAddress, address _senderAddress, 
        address _memberAddress, 
        address _tokenAddress, 
        uint256 _tokenAmount
    );

    event ActDynamicEquityEpochDistributedEvent(
        address _daoAddress, address _senderAddress, 
        uint256 _distributionEpoch
    );

    //SUBMIT
    function submitSetDynamicEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityConfig calldata _dynamicEquityConfig,
        Foundance.EpochConfig calldata _epochConfig
    ) external override reimbursable(dao) {
        string memory origin = "DynamicEquityAdapter.submitSetDynamicEquityProposal";
        setDynamicEquityProposal[address(dao)][proposalId] = DynamicEquityProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _dynamicEquityConfig,
            _epochConfig
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitSetDynamicEquityProposalEvent(address(dao), msg.sender, data, proposalId, _dynamicEquityConfig, _epochConfig);
    }

    function submitSetDynamicEquityEpochProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        uint256 _unixTimestampInS
    ) external override reimbursable(dao) {
        string memory origin = "DynamicEquityAdapter.submitSetDynamicEquityEpochProposal";
        setDynamicEquityEpochProposal[address(dao)][proposalId] = DynamicEquityEpochProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _unixTimestampInS
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin, Foundance.VotingType.OPTIMISTIC);
        emit SubmitSetDynamicEquityEpochProposalEvent(address(dao), msg.sender, data, proposalId, _unixTimestampInS);
    }

    function submitSetDynamicEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig
    ) external override reimbursable(dao) {
        string memory origin = "DynamicEquityAdapter.submitSetDynamicEquityMemberProposal";
        setDynamicEquityMemberProposal[address(dao)][proposalId] = DynamicEquityMemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _dynamicEquityMemberConfig
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitSetDynamicEquityMemberProposalEvent(address(dao), msg.sender, data, proposalId, _dynamicEquityMemberConfig);
    }

    function submitSetDynamicEquityMemberSuspendProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress,
        uint256 _suspendUntil
    ) external override reimbursable(dao) {
        string memory origin = "DynamicEquityAdapter.submitSetDynamicEquityMemberSuspendProposal";
        setDynamicEquityMemberSuspendProposal[address(dao)][proposalId] = MemberValueProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress,
            _suspendUntil
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitSetDynamicEquityMemberSuspendProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress, _suspendUntil);
    }

    function submitSetDynamicEquityMemberEpochProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig
    ) external override reimbursable(dao) {
        string memory origin = "DynamicEquityAdapter.submitSetDynamicEquityMemberEpochProposal";
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
            dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT)
        );
        require(
            dynamicEquity.getIsNotReviewPeriod(dao),
            "dynamicEquityAdpt::submitSetDynamicEquityMemberEpochProposal unavailable during review period"
        );
        setDynamicEquityMemberEpochProposal[address(dao)][proposalId] = DynamicEquityMemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _dynamicEquityMemberConfig
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitSetDynamicEquityMemberEpochProposalEvent(address(dao), msg.sender, data, proposalId, _dynamicEquityMemberConfig);
    }

    function submitSetDynamicEquityMemberEpochExpenseProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress,
        uint256 _expenseAmount
    ) external override reimbursable(dao) {
        string memory origin = "DynamicEquityAdapter.submitSetDynamicEquityMemberEpochExpenseProposal";
        setDynamicEquityMemberEpochExpenseProposal[address(dao)][proposalId] = MemberValueProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress,
            _expenseAmount
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitSetDynamicEquityMemberEpochExpenseProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress, _expenseAmount);
    }

    function submitRemoveDynamicEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external override reimbursable(dao) {
        string memory origin = "DynamicEquityAdapter.submitRemoveDynamicEquityMemberProposal";
        removeDynamicEquityMemberProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitRemoveDynamicEquityMemberProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    }

    function submitRemoveDynamicEquityMemberEpochProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external override reimbursable(dao) {
        string memory origin = "DynamicEquityAdapter.submitRemoveDynamicEquityMemberEpochProposal";
        removeDynamicEquityMemberEpochProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitRemoveDynamicEquityMemberEpochProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    }

    //PROCESS
    function processSetDynamicEquityProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        DynamicEquityProposal storage proposal = setDynamicEquityProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquity(
                dao,
                proposal.dynamicEquityConfig,
                proposal.epochConfig
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityProposalEvent(address(dao), msg.sender, proposalId, proposal.dynamicEquityConfig, proposal.epochConfig);
        }
    }

    function processSetDynamicEquityEpochProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        DynamicEquityEpochProposal storage proposal = setDynamicEquityEpochProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquityEpoch(
                dao,
                proposal.lastEpoch
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityEpochProposalEvent(address(dao), msg.sender, proposalId, proposal.lastEpoch);
        }
    }

    function processSetDynamicEquityMemberProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        DynamicEquityMemberProposal storage proposal = setDynamicEquityMemberProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquityMember(
                dao,
                proposal.dynamicEquityMemberConfig
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.dynamicEquityMemberConfig);
        }
    }
    
    function processSetDynamicEquityMemberSuspendProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberValueProposal storage proposal = setDynamicEquityMemberSuspendProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquityMemberSuspend(
                dao,
                proposal.memberAddress,
                proposal.value
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityMemberSuspendProposalEvent(address(dao), msg.sender, proposalId,  proposal.memberAddress, proposal.value);
        } 
    }

    function processSetDynamicEquityMemberEpochProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        DynamicEquityMemberProposal storage proposal = setDynamicEquityMemberEpochProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquityMemberEpoch(
                dao,
                proposal.dynamicEquityMemberConfig
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityMemberEpochProposalEvent(address(dao), msg.sender, proposalId,  proposal.dynamicEquityMemberConfig);
        }
    }

    function processSetDynamicEquityMemberEpochExpenseProposal(DaoRegistry dao, bytes32 proposalId, uint256 _expenseAmount)
        external
        override
        reimbursable(dao)
    {
        MemberValueProposal storage proposal = setDynamicEquityMemberEpochExpenseProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        require(
            proposal.value >= _expenseAmount,
            "dynamicEquityAdpt::reported expenses have to be less or equal than the initially requested amount"
        );
        require(
            msg.sender == proposal.memberAddress,
            "dynamicEquityAdpt::processing only possible by the member concerning this expense proposal"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoLibrary.BANK_EXT)
            );
            if(_expenseAmount>0){
                bank.addToBalance(
                    dao,
                    proposal.memberAddress,
                    DaoLibrary.UNITS,
                    _expenseAmount
                );
            }
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityMemberEpochExpenseProposalEvent(address(dao), msg.sender, proposalId,  proposal.memberAddress, proposal.value, _expenseAmount);
        }
    }
 
    function processRemoveDynamicEquityMemberProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberProposal storage proposal = removeDynamicEquityMemberProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.removeDynamicEquityMember(
                dao,
                proposal.memberAddress
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessRemoveDynamicEquityMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress);
        }
    }
   
    function processRemoveDynamicEquityMemberEpochProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberProposal storage proposal = removeDynamicEquityMemberEpochProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.removeDynamicEquityMemberEpoch(
                dao,
                proposal.memberAddress
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessRemoveDynamicEquityMemberEpochProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress);
        }
    }

    //ACT
    function actDynamicEquityEpochDistributed(DaoRegistry dao)
        external
        override
        reimbursable(dao)
    {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
            dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT)
        );
        address token = DaoLibrary.UNITS;
        require(
            bank.isTokenAllowed(token),
            "token not allowed"
        );
        Foundance.EpochConfig memory epochConfig = dynamicEquity.getEpochConfig();
        uint256 blockTimestamp = block.timestamp;
        uint256 nbMembers = dao.getNbMembers();
        uint256 distributionEpoch = epochConfig.epochLast+epochConfig.epochDuration;
        while(distributionEpoch < blockTimestamp){
            for (uint256 i = 0; i < nbMembers; i++) {
                address memberAddress = dao.getMemberAddress(i);
                uint256 suspendedUntil = dynamicEquity.getDynamicEquityMemberSuspendedUntil(memberAddress);
                if(suspendedUntil < distributionEpoch){
                    uint256 amount = dynamicEquity.getDynamicEquityMemberEpochAmount(memberAddress);
                    if(amount > 0){
                        bank.addToBalance(
                            dao,
                            memberAddress,
                            token,
                            amount
                        );
                    }
                    emit ActDynamicEquityMemberEpochDistributedEvent(address(dao), msg.sender, memberAddress, token, amount);
                }
            }
            dynamicEquity.setDynamicEquityEpoch(dao, epochConfig.epochDuration+epochConfig.epochLast);
            distributionEpoch+=epochConfig.epochDuration;
        }
        emit ActDynamicEquityEpochDistributedEvent(address(dao), msg.sender, distributionEpoch);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import "./interfaces/IVotingAdapter.sol";
import "./interfaces/IVestedEquityAdapter.sol";
import "../core/DaoRegistry.sol";
import "../extensions/BankExtension.sol";
import "../extensions/VestedEquityExtension.sol";
import "../libraries/DaoLibrary.sol";
import "../libraries/VotingAdapterLibrary.sol";
import "../libraries/GovernanceLibrary.sol";
import "../modifiers/AdapterGuard.sol";
import "../modifiers/Reimbursable.sol";




contract VestedEquityAdapter is IVestedEquity, AdapterGuard, Reimbursable {

    struct VestedEquityMemberProposal {
        Foundance.ProposalStatus status;
        Foundance.VestedEquityMemberConfig vestedEquityMemberConfig;
    }
    struct MemberProposal {
        Foundance.ProposalStatus status;
        address memberAddress;
    }

    mapping(address => mapping(bytes32 => VestedEquityMemberProposal)) public setVestedEquityMemberProposal;

    mapping(address => mapping(bytes32 => MemberProposal)) public removeVestedEquityMemberProposal;

    //EVENT
    event SubmitSetVestedEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId, 
        Foundance.VestedEquityMemberConfig _vestedEquityMemberConfig
    );

    event SubmitRemoveVestedEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId, 
        address _memberAddress
    );

    event ProcessSetVestedEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId, 
        Foundance.VestedEquityMemberConfig _vestedEquityMemberConfig
    );

    event ProcessRemoveVestedEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId, 
        address _memberAddress
    );

    event ActVestedEquityMemberDistributedEvent(
        address _daoAddress, address _senderAddress, 
        address _memberAddress, 
        address _tokenAddress, 
        uint256 _tokenAmount
    );

    //SUBMIT
    function submitSetVestedEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.VestedEquityMemberConfig calldata _vestedEquityMemberConfig
    ) external override reimbursable(dao) {
        string memory origin = "VestedEquityAdapter.submitSetVestedEquityMemberProposal";
        setVestedEquityMemberProposal[address(dao)][proposalId] = VestedEquityMemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _vestedEquityMemberConfig
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitSetVestedEquityMemberProposalEvent(address(dao), msg.sender, data, proposalId, _vestedEquityMemberConfig);
    }

    function submitRemoveVestedEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external override reimbursable(dao) {
        string memory origin = "VestedEquityAdapter.submitRemoveVestedEquityMemberProposal";
        removeVestedEquityMemberProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitRemoveVestedEquityMemberProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    }

    //PROCESS
    function processSetVestedEquityMemberProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        VestedEquityMemberProposal storage proposal = setVestedEquityMemberProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            VestedEquityExtension vestedEquity = VestedEquityExtension(
                dao.getExtensionAddress(DaoLibrary.VESTED_EQUITY_EXT)
            );
            vestedEquity.setVestedEquityMember(
                dao,
                proposal.vestedEquityMemberConfig
            );
            emit ProcessSetVestedEquityMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.vestedEquityMemberConfig);
            proposal.status == Foundance.ProposalStatus.DONE;
        } 
    }

    function processRemoveVestedEquityMemberProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberProposal storage proposal = removeVestedEquityMemberProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            VestedEquityExtension vestedEquity = VestedEquityExtension(
                dao.getExtensionAddress(DaoLibrary.VESTED_EQUITY_EXT)
            );
            vestedEquity.removeVestedEquityMember(
                dao,
                proposal.memberAddress
            );
            emit ProcessRemoveVestedEquityMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        }
    }

    //ACT_INTERNAL
    function _actVestedEquityMemberDistributed(
        DaoRegistry dao,
        BankExtension bank,
        VestedEquityExtension vestedEquity,
        address _memberAddress,
        address token
    )
        internal
    {
        Foundance.VestedEquityMemberConfig memory vestedEquityMemberConfig = vestedEquity.getVestedEquityMemberConfig(_memberAddress); 
        uint256 tokenAmount = vestedEquityMemberConfig.tokenAmount;
        vestedEquity.removeVestedEquityMemberAmount(dao, _memberAddress);       
        uint256 newAmount = vestedEquity.getVestedEquityMemberAmount(_memberAddress);
        uint256 tokenAmountToDistributed = tokenAmount - newAmount;
        if(tokenAmountToDistributed>0){
            bank.addToBalance(
                dao,
                _memberAddress,
                token,
                tokenAmountToDistributed
            );
        }
        emit ActVestedEquityMemberDistributedEvent(address(dao), msg.sender, _memberAddress, token, tokenAmountToDistributed);
    }

    //ACT
    function actVestedEquityMemberDistributed(
        DaoRegistry dao,
        address memberAddress
    )
        external override reimbursable(dao)
    {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        VestedEquityExtension vestedEquity = VestedEquityExtension(
            dao.getExtensionAddress(DaoLibrary.VESTED_EQUITY_EXT)
        );
        address token = DaoLibrary.UNITS;
        require(
            bank.isTokenAllowed(token),
            "vestedEquityAdpt::token not allowed"
        );
        if (memberAddress != address(0x0)) {
            _actVestedEquityMemberDistributed(dao, bank, vestedEquity, memberAddress, token);  
        }else{
            uint256 nbMembers = dao.getNbMembers();
            for (uint256 i = 0; i < nbMembers; i++) {
                address _memberAddress = dao.getMemberAddress(i);
                if(DaoLibrary.isNotReservedAddress(_memberAddress)){
                    _actVestedEquityMemberDistributed(dao, bank, vestedEquity, _memberAddress, token);          
                }
            }
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import "./interfaces/IVotingAdapter.sol";
import "./interfaces/ICommunityEquityAdapter.sol";
import "../core/DaoRegistry.sol";
import "../extensions/CommunityEquityExtension.sol";
import "../extensions/BankExtension.sol";
import "../extensions/MemberExtension.sol";
import "../modifiers/AdapterGuard.sol";
import "../modifiers/Reimbursable.sol";
import "../libraries/VotingAdapterLibrary.sol";
import "../libraries/GovernanceLibrary.sol";
import "../libraries/DaoLibrary.sol";


contract CommunityEquityAdapter is ICommunityEquity, AdapterGuard, Reimbursable {
    
    struct CommunityEquityProposal {
        Foundance.ProposalStatus status;
        Foundance.CommunityEquityConfig communityEquityConfig;
        Foundance.EpochConfig epochConfig;
    }

    struct CommunityEquityMemberProposal {
        Foundance.ProposalStatus status;
        Foundance.CommunityEquityMemberConfig communityEquityMemberConfig;
    }

    struct MemberProposal {
        Foundance.ProposalStatus status;
        address memberAddress;
    }

    mapping(address => mapping(bytes32 => CommunityEquityProposal)) public setCommunityEquityProposal;

    mapping(address => mapping(bytes32 => CommunityEquityMemberProposal)) public setCommunityEquityMemberProposal;

    mapping(address => mapping(bytes32 => MemberProposal)) public removeCommunityEquityProposal;

    mapping(address => mapping(bytes32 => MemberProposal)) public removeCommunityEquityMemberProposal;

    mapping(address => bytes32) public ongoingCommunityEquityDistribution;

    //EVENT
    event SubmitSetCommunityEquityProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        Foundance.CommunityEquityConfig _communityEquityConfig, 
        Foundance.EpochConfig _epochConfig
    );
        
    event SubmitSetCommunityEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        Foundance.CommunityEquityMemberConfig _communityEquityMemberConfig
    );
        
    event SubmitRemoveCommunityEquityProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId);

    event SubmitRemoveCommunityEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, 
        address _memberAddress
    );

    event ProcessSetCommunityEquityProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        Foundance.CommunityEquityConfig _communityEquityConfig, 
        Foundance.EpochConfig _epochConfig
    );
    
    event ProcessSetCommunityEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        Foundance.CommunityEquityMemberConfig _communityEquityMemberConfig
    );

    event ProcessRemoveCommunityEquityProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId
    );

    event ProcessRemoveCommunityEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, 
        address _memberAddress
    );
    
    event ActCommunityEquityMemberDistributedEvent(
        address _daoAddress, address _senderAddress, 
        address _memberAddress, 
        uint256 amountToBeSent
    );

    event ActCommunityEquityEpochDistributedEvent(
        address _daoAddress, address _senderAddress
    );
    
    //SUBMIT
    function submitSetCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.CommunityEquityConfig calldata _communityEquityConfig,
        Foundance.EpochConfig calldata _epochConfig
    ) external override reimbursable(dao) {
        string memory origin = "CommunityEquityAdapter.submitSetCommunityEquityProposal";
        setCommunityEquityProposal[address(dao)][proposalId] = CommunityEquityProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _communityEquityConfig,
            _epochConfig
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitSetCommunityEquityProposalEvent(address(dao), msg.sender, data, proposalId,_communityEquityConfig, _epochConfig);
    }

    function submitSetCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.CommunityEquityMemberConfig calldata _communityEquityMemberConfig
    ) external override reimbursable(dao) {
        string memory origin = "CommunityEquityAdapter.submitSetCommunityEquityMemberProposal";
        setCommunityEquityMemberProposal[address(dao)][proposalId] = CommunityEquityMemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _communityEquityMemberConfig
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitSetCommunityEquityMemberProposalEvent(address(dao), msg.sender, data, proposalId, _communityEquityMemberConfig);
    }
 
    function submitRemoveCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data
    ) external override reimbursable(dao) {
        string memory origin = "CommunityEquityAdapter.submitRemoveCommunityEquityProposal";
        removeCommunityEquityProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            msg.sender
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitRemoveCommunityEquityProposalEvent(address(dao), msg.sender, data, proposalId);
    }

    function submitRemoveCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external override reimbursable(dao) {        
        string memory origin = "CommunityEquityAdapter.submitRemoveCommunityEquityMemberProposal";
        removeCommunityEquityMemberProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        VotingAdapterLibrary._submitProposal(dao, proposalId, data, origin);
        emit SubmitRemoveCommunityEquityMemberProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    } 

    //PROCESS_INTERNAL
    function _processRemoveCommunityEquity(
        DaoRegistry dao,
        CommunityEquityExtension communityEquity,
        BankExtension bank
    ) internal {
        Foundance.CommunityEquityConfig memory communityEquityConfig = communityEquity.getCommunityEquityConfig(); 
        uint256 tokenAmountToBeRemoved = communityEquityConfig.tokenAmount;
        uint guildTokenAmount = bank.balanceOf(DaoLibrary.GUILD,DaoLibrary.UNITS);
        if(
            tokenAmountToBeRemoved>0 &&
            guildTokenAmount>=tokenAmountToBeRemoved
        ){
            bank.subtractFromBalance(
                dao,
                DaoLibrary.GUILD,
                DaoLibrary.UNITS,
                tokenAmountToBeRemoved
            );
        }
        communityEquity.removeCommunityEquity(
            dao
        );
    }

    //PROCESS
    function processSetCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) external override reimbursable(dao) {
        CommunityEquityProposal storage proposal = setCommunityEquityProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "communityEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            CommunityEquityExtension communityEquity = CommunityEquityExtension(
                dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
            );
            BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoLibrary.BANK_EXT)
            );
            _processRemoveCommunityEquity(dao, communityEquity, bank);
            communityEquity.setCommunityEquity(
                dao,
                proposal.communityEquityConfig,
                proposal.epochConfig
            );
            bank.addToBalance(
                dao,
                DaoLibrary.GUILD,
                DaoLibrary.UNITS,
                proposal.communityEquityConfig.tokenAmount
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetCommunityEquityProposalEvent(address(dao), msg.sender, proposalId,proposal.communityEquityConfig, proposal.epochConfig);
        }
    }

    function processSetCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) external override reimbursable(dao) {
        CommunityEquityMemberProposal storage proposal = setCommunityEquityMemberProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "communityEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            CommunityEquityExtension communityEquity = CommunityEquityExtension(
                dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
            );
            communityEquity.setCommunityEquityMember(
                dao,
                proposal.communityEquityMemberConfig
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetCommunityEquityMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.communityEquityMemberConfig);
        }
    }
  
    function processRemoveCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) external override reimbursable(dao) {
        MemberProposal storage proposal = removeCommunityEquityProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "communityEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            CommunityEquityExtension communityEquity = CommunityEquityExtension(
                dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
            );
            BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoLibrary.BANK_EXT)
            );
            _processRemoveCommunityEquity(dao, communityEquity, bank);
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessRemoveCommunityEquityProposalEvent(address(dao), msg.sender, proposalId);
        }
    }

    function processRemoveCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) external override reimbursable(dao) {
        MemberProposal storage proposal = removeCommunityEquityMemberProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "communityEquityAdpt::proposal already completed or in progress"
        );
        proposal.status =VotingAdapterLibrary._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            CommunityEquityExtension communityEquity = CommunityEquityExtension(
                dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
            );
            communityEquity.removeCommunityEquityMember(
                dao,
                proposal.memberAddress
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessRemoveCommunityEquityMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress);
        }
    }

    //ACT_INTERNAL
    function _actCommunityEquityMemberDistributed(
        DaoRegistry dao,
        bytes32 distributionId
    ) internal {
        ongoingCommunityEquityDistribution[address(dao)] = distributionId;
    }

    //ACT
    function actCommunityEquityMemberDistributed(
        DaoRegistry dao, 
        address memberAddress,
        uint256 amountToBeSent,
        bytes32 distributionId 
    ) external override reimbursable(dao) {        
        CommunityEquityExtension communityEquity = CommunityEquityExtension(
            dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
        );
        Foundance.CommunityEquityMemberConfig memory communityEquityMemberConfig = communityEquity.getCommunityEquityMemberConfig(memberAddress);
        require(
            communityEquity.getIsCommunityEquityMember(msg.sender),
            "communityEquityAdpt::msg.sender not allowed to distribute community equity"
        );
        require(
            amountToBeSent < communityEquityMemberConfig.singlePaymentAmountThreshold,
            "communityEquityAdpt::amount to be sent has to be less than singlePaymentAmountThreshold"
        );
        require(
            communityEquityMemberConfig.totalPaymentAmount+amountToBeSent<communityEquityMemberConfig.totalPaymentAmountThreshold,
            "communityEquityAdpt::total amount to be sent has to be less than totalPaymentAmountThreshold"
        );
        BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        require(
            bank.balanceOf(DaoLibrary.GUILD,DaoLibrary.UNITS)>=amountToBeSent,
            "communityEquityAdpt::amountToBeSent has to be less than available Tokens in the GUILD"
        );
        Foundance.CommunityEquityConfig memory communityEquityConfig = communityEquity.getCommunityEquityConfig();
        require(
            communityEquityConfig.tokenAmount>=amountToBeSent,
            "communityEquityAdpt::amountToBeSent has to be less than available Tokens in the Community Equity Allocation"
        );
        _actCommunityEquityMemberDistributed(dao, distributionId);
        require(
            ongoingCommunityEquityDistribution[address(dao)]==0,
            "communityEquityAdpt::has to wait until ongoingDistribution is done"
        );
        communityEquityConfig.tokenAmount -= amountToBeSent;
        communityEquity.setCommunityEquity(dao, communityEquityConfig);
        MemberExtension member = MemberExtension(
            dao.getExtensionAddress(DaoLibrary.MEMBER_EXT)
        );
        if(member.getIsMember(memberAddress)){            
            bank.addToBalance(
                dao,
                memberAddress,
                DaoLibrary.UNITS,
                amountToBeSent
            );
        }
        else{
            member.setMember(
                dao,
                Foundance.MemberConfig(
                    memberAddress,
                    amountToBeSent,
                    block.timestamp,
                    false
                )
            );
        }
        bank.subtractFromBalance(
            dao,
            DaoLibrary.GUILD,
            DaoLibrary.UNITS,
            amountToBeSent
        );
        communityEquityMemberConfig.totalPaymentAmount += amountToBeSent;
        communityEquity.setCommunityEquityMember(dao,communityEquityMemberConfig);
        _actCommunityEquityMemberDistributed(dao, 0);
        emit ActCommunityEquityMemberDistributedEvent(address(dao), msg.sender, memberAddress, amountToBeSent);
    }
    
    function actCommunityEquityEpochDistributed(
        DaoRegistry dao
    ) external override reimbursable(dao) { 
        //TODO
        emit ActCommunityEquityEpochDistributedEvent(address(dao), msg.sender);
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// SPDX-License-Identifier: MIT
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../../interfaces/IFactory.sol";
import "../BankExtension.sol";

contract BankExtensionFactory is 
    IFactory,
    CloneFactory,
    ReentrancyGuard 
{
    address public identityAddress;
    
    event ExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "bankExtFactory::invalid addr");
        identityAddress = _identityAddress;
    }

    function create(DaoRegistry dao, uint8 maxExternalTokens)
        external
        nonReentrant
    {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "bankExtFactory::invalid dao addr");
        address extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;
        BankExtension extension = BankExtension(
            extensionAddr
        );

        extension.setMaxExternalTokens(maxExternalTokens);
        extension.initialize(dao, dao.getMemberAddress(1));

        emit ExtensionCreated(
            daoAddress,
            address(extension)
        );
    }

    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// SPDX-License-Identifier: MIT
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../../interfaces/IFactory.sol";
import "../ERC20Extension.sol";

contract ERC20ExtensionFactory is 
    IFactory,
    CloneFactory,
    ReentrancyGuard 
{
    address public identityAddress;

    event ExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "erc20ExtFactory::invalid addr");
        identityAddress = _identityAddress;
    }

    function create(
        DaoRegistry dao,
        string calldata tokenName,
        address tokenAddress,
        string calldata tokenSymbol,
        uint8 decimals
    ) 
        external 
        nonReentrant 
    {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "erc20ExtFactory::invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;
        ERC20Extension extension = ERC20Extension(
            extensionAddr
        );

        extension.setName(tokenName);
        extension.setToken(tokenAddress);
        extension.setSymbol(tokenSymbol);
        extension.setDecimals(decimals);
        extension.initialize(dao, address(0));

        emit ExtensionCreated(daoAddress, address(extension));
    }

    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../../interfaces/IFactory.sol";
import "../MemberExtension.sol";


contract MemberExtensionFactory is
    IFactory,
    CloneFactory,
    ReentrancyGuard
{
    address public identityAddress;

    event ExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "memberExtFactory::invalid addr");
        identityAddress = _identityAddress;
    }

    function create(DaoRegistry dao) 
        external
        nonReentrant 
    {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "memberExtFactory::invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;
        MemberExtension extension = MemberExtension(
            extensionAddr
        );

        extension.initialize(dao, address(0));

        emit ExtensionCreated(
            daoAddress,
            address(extension)
        );
    }
    
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../../interfaces/IFactory.sol";
import "../DynamicEquityExtension.sol";


contract DynamicEquityExtensionFactory is
    IFactory,
    CloneFactory,
    ReentrancyGuard
{
    address public identityAddress;

    event ExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "dynamicEquityExtFactory::invalid addr");
        identityAddress = _identityAddress;
    }

    function create(DaoRegistry dao) external nonReentrant {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "dynamicEquityExtFactory::invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;

        DynamicEquityExtension extension = DynamicEquityExtension(
            extensionAddr
        );

        extension.initialize(dao, address(0));
        emit ExtensionCreated(
            daoAddress,
            address(extension)
        );
    }
    
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../../interfaces/IFactory.sol";
import "../VestedEquityExtension.sol";


contract VestedEquityExtensionFactory is
    IFactory,
    CloneFactory,
    ReentrancyGuard
{
    address public identityAddress;

    event ExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "vestedEquityExtFactory::invalid addr");
        identityAddress = _identityAddress;
    }

    function create(DaoRegistry dao) external nonReentrant {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "vestedEquityExtFactory::invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;
        VestedEquityExtension extension = VestedEquityExtension(
            extensionAddr
        );

        extension.initialize(dao, address(0));

        emit ExtensionCreated(
            daoAddress,
            address(extension)
        );
    }
    
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../../interfaces/IFactory.sol";
import "../CommunityEquityExtension.sol";

contract CommunityEquityExtensionFactory is
    IFactory,
    CloneFactory,
    ReentrancyGuard
{
    address public identityAddress;

    event ExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "communityEquityExtFactory::invalid addr");
        identityAddress = _identityAddress;
    }

    function create(DaoRegistry dao) 
        external 
        nonReentrant
    {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "communityEquityExtFactory::invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;
        CommunityEquityExtension extension = CommunityEquityExtension(
            extensionAddr
        );

        extension.initialize(dao, address(0));

        emit ExtensionCreated(
            daoAddress,
            address(extension)
        );
    }
    
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../extensions/BankExtension.sol";
import "../core/DaoRegistry.sol";

library DaoLibrary {


    // EXTENSIONS
    bytes32 internal constant BANK_EXT = keccak256("bank-ext");
    bytes32 internal constant ERC20_EXT = keccak256("erc20-ext");
    bytes32 internal constant MEMBER_EXT = keccak256("member-ext"); 
    bytes32 internal constant DYNAMIC_EQUITY_EXT = keccak256("dynamic-equity-ext");
    bytes32 internal constant VESTED_EQUITY_EXT = keccak256("vested-equity-ext");
    bytes32 internal constant COMMUNITY_EQUITY_EXT = keccak256("community-equity-ext"); 
    
    // ADAPTER
    bytes32 internal constant ERC20_ADPT = keccak256("erc20-adpt");
    bytes32 internal constant MANAGER_ADPT = keccak256("manager-adpt");
    bytes32 internal constant VOTING_ADPT = keccak256("voting-adpt");
    bytes32 internal constant MEMBER_ADPT = keccak256("member-adpt"); 
    bytes32 internal constant DYNAMIC_EQUITY_ADPT = keccak256("dynamic-equity-adpt");
    bytes32 internal constant VESTED_EQUITY_ADPT = keccak256("vested-equity-adpt"); 
    bytes32 internal constant COMMUNITY_EQUITY_ADPT = keccak256("community-equity-adpt");

    // UTIL
    bytes32 internal constant REIMBURSEMENT_ADPT = keccak256("reimbursament-adpt");
    bytes32 internal constant FOUNDANCE_FACTORY = keccak256("foundance-factory");


    // ADDRESSES
    address internal constant GUILD = address(0xdead);
    address internal constant ESCROW = address(0x4bec);
    address internal constant TOTAL = address(0xbabe);
    address internal constant UNITS = address(0xFF1CE);
    address internal constant LOOT = address(0xB105F00D);
    address internal constant ETH_TOKEN = address(0x0);
    address internal constant MEMBER_COUNT = address(0xDECAFBAD);

    // CONSTANTS
    uint256 internal constant FOUNDANCE_WORKDAYS_WEEK = 5;
    uint256 internal constant FOUNDANCE_MONTHS_YEAR = 12;
    uint256 internal constant FOUNDANCE_WEEKS_MONTH = 434524;
    uint256 internal constant FOUNDANCE_WEEKS_MONTH_PRECISION = 5;
    uint256 internal constant FOUNDANCE_PRECISION = 5;
    uint8   internal constant MAX_TOKENS_GUILD_BANK = 200;


    function totalTokens(BankExtension bank) internal view returns (uint256) {
        return memberTokens(bank, TOTAL) - memberTokens(bank, GUILD); //GUILD is accounted for twice otherwise
    }

    function totalUnitTokens(BankExtension bank) internal view returns (uint256) {
        return  bank.balanceOf(TOTAL, UNITS) - bank.balanceOf(GUILD, UNITS); //GUILD is accounted for twice otherwise
    }
    /**
     * @notice calculates the total number of units.
     */
    function priorTotalTokens(BankExtension bank, uint256 at)
        internal
        view
        returns (uint256)
    {
        return
            priorMemberTokens(bank, TOTAL, at) -
            priorMemberTokens(bank, GUILD, at);
    }

    function memberTokens(BankExtension bank, address member)
        internal
        view
        returns (uint256)
    {
        return bank.balanceOf(member, UNITS) + bank.balanceOf(member, LOOT);
    }

    function msgSender(DaoRegistry dao, address addr)
        internal
        view
        returns (address)
    {
        address memberAddress = dao.getAddressIfDelegated(addr);
        address delegatedAddress = dao.getCurrentDelegateKey(addr);

        require(
            memberAddress == delegatedAddress || delegatedAddress == addr,
            "call with your delegate key"
        );

        return memberAddress;
    }

    /**
     * @notice calculates the total number of units.
     */
    function priorMemberTokens(
        BankExtension bank,
        address member,
        uint256 at
    ) internal view returns (uint256) {
        return
            bank.getPriorAmount(member, UNITS, at) +
            bank.getPriorAmount(member, LOOT, at);
    }

    //helper
    function getFlag(uint256 flags, uint256 flag) internal pure returns (bool) {
        return (flags >> uint8(flag)) % 2 == 1;
    }

    function setFlag(
        uint256 flags,
        uint256 flag,
        bool value
    ) internal pure returns (uint256) {
        if (getFlag(flags, flag) != value) {
            if (value) {
                return flags + 2**flag;
            } else {
                return flags - 2**flag;
            }
        } else {
            return flags;
        }
    }

    /**
     * @notice Checks if a given address is reserved.
     */
    function isNotReservedAddress(address addr) internal pure returns (bool) {
        return addr != GUILD && addr != TOTAL && addr != ESCROW && addr != address(0);
    }

    /**
     * @notice Checks if a given address is zeroed.
     */
    function isNotZeroAddress(address addr) internal pure returns (bool) {
        return addr != address(0x0);
    }

    function potentialNewMember(
        address memberAddress,
        DaoRegistry dao,
        BankExtension bank
    ) internal {
        dao.potentialNewMember(memberAddress);
        require(memberAddress != address(0x0), "invalid member address");
        if (address(bank) != address(0x0)) {
            if (bank.balanceOf(memberAddress, MEMBER_COUNT) == 0) {
                bank.addToBalance(dao, memberAddress, MEMBER_COUNT, 1);
            }
        }
    }

    /**
     * A DAO is in creation mode is the state of the DAO is equals to CREATION and
     * 1. The number of members in the DAO is ZERO or,
     * 2. The sender of the tx is a DAO member (usually the DAO owner) or,
     * 3. The sender is an adapter.
     */
    // slither-disable-next-line calls-loop
    function isInCreationModeAndHasAccess(DaoRegistry dao)
        internal
        view
        returns (bool)
    {
        return
            dao.state() == DaoRegistry.DaoState.CREATION &&
            (dao.getNbMembers() == 0 ||
                dao.isMember(msg.sender) ||
                dao.isAdapter(msg.sender));
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";

interface IExtension {
    function initialize(DaoRegistry dao, address creator) external;
}

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

contract CloneFactory {
    function _createClone(address target)
        internal
        returns (address payable result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
        require(result != address(0), "create failed");
    }

    function _isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";
import "../libraries/DaoLibrary.sol";

abstract contract AdapterGuard {
    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier onlyAdapter(DaoRegistry dao) {
        require(
            dao.isAdapter(msg.sender) ||
                DaoLibrary.isInCreationModeAndHasAccess(dao),
            "onlyAdapter"
        );
        _;
    }

    modifier reentrancyGuard(DaoRegistry dao) {
        require(dao.lockedAt() != block.number, "reentrancy guard");
        dao.lockSession();
        _;
        dao.unlockSession();
    }

    modifier executorFunc(DaoRegistry dao) {
        address executorAddr = dao.getExtensionAddress(
            keccak256("executor-ext")
        );
        require(address(this) == executorAddr, "only callable by the executor");
        _;
    }

    modifier hasAccess(DaoRegistry dao, DaoRegistry.AclFlag flag) {
        require(
            DaoLibrary.isInCreationModeAndHasAccess(dao) ||
                dao.hasAdapterAccess(msg.sender, flag),
            "accessDenied"
        );
        _;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";
import "../extensions/BankExtension.sol";
import "../libraries/DaoLibrary.sol";

abstract contract MemberGuard {
    /**
     * @dev Only members of the DAO are allowed to execute the function call.
     */
    modifier onlyMember(DaoRegistry dao) {
        _onlyMember(dao, msg.sender);
        _;
    }

    modifier onlyMember2(DaoRegistry dao, address _addr) {
        _onlyMember(dao, _addr);
        _;
    }

    function _onlyMember(DaoRegistry dao, address _addr) internal view {
        require(isActiveMember(dao, _addr), "onlyMember");
    }

    function isActiveMember(DaoRegistry dao, address _addr)
        public
        view
        returns (bool)
    {
        address bankAddress = dao.extensions(DaoLibrary.BANK_EXT);
        if (bankAddress != address(0x0)) {
            address memberAddr = DaoLibrary.msgSender(dao, _addr);
            return
                dao.isMember(_addr) &&
                BankExtension(bankAddress).balanceOf(
                    memberAddr,
                    DaoLibrary.UNITS
                ) >
                0;
        }

        return dao.isMember(_addr);
    }
}

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
// SPDX-License-Identifier: MIT
import '../core/DaoRegistry.sol';
import '../interfaces/IExtension.sol';
import '../libraries/DaoLibrary.sol';
import '../modifiers/AdapterGuard.sol';


contract BankExtension is 
    IExtension,
    ERC165 
{
    using Address for address payable;
    using SafeERC20 for IERC20;

    enum AclFlag {
        ADD_TO_BALANCE,
        SUB_FROM_BALANCE,
        INTERNAL_TRANSFER,
        WITHDRAW,
        REGISTER_NEW_TOKEN,
        REGISTER_NEW_INTERNAL_TOKEN,
        UPDATE_TOKEN
    }

    event NewBalance(
        address member,
        address tokenAddr,
        uint160 amount
    );

    event Withdraw(
        address account, 
        address tokenAddr, 
        uint160 amount
    );

    event WithdrawTo(
        address accountFrom,
        address accountTo,
        address tokenAddr,
        uint160 amount
    );
    
    bool public initialized;
    
    DaoRegistry private _dao;

    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            _dao == dao &&
                (address(this) == msg.sender ||
                    address(_dao) == msg.sender ||
                    !initialized ||
                    DaoLibrary.isInCreationModeAndHasAccess(_dao) ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "bankExt::accessDenied"
        );
        _;
    }

    modifier noProposal() {
        require(_dao.lockedAt() < block.number, 'proposal lock');
        _;
    }

    uint8 public maxExternalTokens; // the maximum number of external tokens that can be stored in the bank
    
    struct Checkpoint {
        // A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    address[] public tokens;
    address[] public internalTokens;
    // tokenAddress => availability
    mapping(address => bool) public availableTokens;
    mapping(address => bool) public availableInternalTokens;
    // tokenAddress => memberAddress => checkpointNum => Checkpoint
    mapping(address => mapping(address => mapping(uint32 => Checkpoint)))
        public checkpoints;
    // tokenAddress => memberAddress => numCheckpoints
    mapping(address => mapping(address => uint32)) public numCheckpoints;

    constructor() {}

    function initialize(DaoRegistry dao, address creator) external override {
        require(!initialized, 'already initialized');
        require(dao.isMember(creator), 'not a member');
        _dao = dao;
        availableInternalTokens[DaoLibrary.UNITS] = true;
        internalTokens.push(DaoLibrary.UNITS);
        availableInternalTokens[DaoLibrary.MEMBER_COUNT] = true;
        internalTokens.push(DaoLibrary.MEMBER_COUNT);
        uint256 nbMembers = dao.getNbMembers();
        for (uint256 i = 0; i < nbMembers; i++) {
            addToBalance(
                dao,
                dao.getMemberAddress(i),
                DaoLibrary.MEMBER_COUNT,
                1
            );
        }
        _createNewAmountCheckpoint(creator, DaoLibrary.UNITS, 1);
        _createNewAmountCheckpoint(DaoLibrary.TOTAL, DaoLibrary.UNITS, 1);
        initialized = true;
    }

    function withdraw(
        DaoRegistry dao,
        address payable member,
        address tokenAddr,
        uint256 amount
    ) external hasExtensionAccess(dao, AclFlag.WITHDRAW) {
        require(
            balanceOf(member, tokenAddr) >= amount,
            'bank::withdraw::not enough funds'
        );
        subtractFromBalance(dao, member, tokenAddr, amount);
        if (tokenAddr == DaoLibrary.ETH_TOKEN) {
            member.sendValue(amount);
        } else {
            IERC20(tokenAddr).safeTransfer(member, amount);
        }
        emit Withdraw(member, tokenAddr, uint160(amount));
    }

    function withdrawTo(
        DaoRegistry dao,
        address memberFrom,
        address payable memberTo,
        address tokenAddr,
        uint256 amount
    ) external hasExtensionAccess(dao, AclFlag.WITHDRAW) {
        require(
            balanceOf(memberFrom, tokenAddr) >= amount,
            'bank::withdraw::not enough funds'
        );
        subtractFromBalance(dao, memberFrom, tokenAddr, amount);
        if (tokenAddr == DaoLibrary.ETH_TOKEN) {
            memberTo.sendValue(amount);
        } else {
            IERC20(tokenAddr).safeTransfer(memberTo, amount);
        }

        //slither-disable-next-line reentrancy-events
        emit WithdrawTo(memberFrom, memberTo, tokenAddr, uint160(amount));
    }

    /**
     * @return Whether or not the given token is an available internal token in the bank
     * @param token The address of the token to look up
     */
    function isInternalToken(address token) external view returns (bool) {
        return availableInternalTokens[token];
    }

    /**
     * @return Whether or not the given token is an available token in the bank
     * @param token The address of the token to look up
     */
    function isTokenAllowed(address token) public view returns (bool) {
        return availableTokens[token];
    }

    /**
     * @notice Sets the maximum amount of external tokens allowed in the bank
     * @param maxTokens The maximum amount of token allowed
     */
    function setMaxExternalTokens(uint8 maxTokens) external {
        require(!initialized, 'already initialized');
        require(
            maxTokens > 0 && maxTokens <= DaoLibrary.MAX_TOKENS_GUILD_BANK,
            'maxTokens should be (0,200]'
        );
        maxExternalTokens = maxTokens;
    }

    /*
     * BANK
     */

    /**
     * @notice Registers a potential new token in the bank
     * @dev Cannot be a reserved token or an available internal token
     * @param token The address of the token
     */
    function registerPotentialNewToken(DaoRegistry dao, address token)
        external
        hasExtensionAccess(dao, AclFlag.REGISTER_NEW_TOKEN)
    {
        require(DaoLibrary.isNotReservedAddress(token), 'reservedToken');
        require(!availableInternalTokens[token], 'internalToken');
        require(
            tokens.length <= maxExternalTokens,
            'exceeds the maximum tokens allowed'
        );

        if (!availableTokens[token]) {
            availableTokens[token] = true;
            tokens.push(token);
        }
    }

    /**
     * @notice Registers a potential new internal token in the bank
     * @dev Can not be a reserved token or an available token
     * @param token The address of the token
     */
    function registerPotentialNewInternalToken(DaoRegistry dao, address token)
        external
        hasExtensionAccess(dao, AclFlag.REGISTER_NEW_INTERNAL_TOKEN)
    {
        require(DaoLibrary.isNotReservedAddress(token), 'reservedToken');
        require(!availableTokens[token], 'availableToken');

        if (!availableInternalTokens[token]) {
            availableInternalTokens[token] = true;
            internalTokens.push(token);
        }
    }

    function updateToken(DaoRegistry dao, address tokenAddr)
        external
        hasExtensionAccess(dao, AclFlag.UPDATE_TOKEN)
    {
        require(isTokenAllowed(tokenAddr), 'token not allowed');
        uint256 totalBalance = balanceOf(DaoLibrary.TOTAL, tokenAddr);

        uint256 realBalance;

        if (tokenAddr == DaoLibrary.ETH_TOKEN) {
            realBalance = address(this).balance;
        } else {
            IERC20 erc20 = IERC20(tokenAddr);
            realBalance = erc20.balanceOf(address(this));
        }

        if (totalBalance < realBalance) {
            addToBalance(
                dao,
                DaoLibrary.GUILD,
                tokenAddr,
                realBalance - totalBalance
            );
        } else if (totalBalance > realBalance) {
            uint256 tokensToRemove = totalBalance - realBalance;
            uint256 guildBalance = balanceOf(DaoLibrary.GUILD, tokenAddr);
            if (guildBalance > tokensToRemove) {
                subtractFromBalance(
                    dao,
                    DaoLibrary.GUILD,
                    tokenAddr,
                    tokensToRemove
                );
            } else {
                subtractFromBalance(
                    dao,
                    DaoLibrary.GUILD,
                    tokenAddr,
                    guildBalance
                );
            }
        }
    }

    /**
     * Public read-only functions
     */

    /**
     * Internal bookkeeping
     */

    /**
     * @return The token from the bank of a given index
     * @param index The index to look up in the bank's tokens
     */
    function getToken(uint256 index) external view returns (address) {
        return tokens[index];
    }

    /**
     * @return The amount of token addresses in the bank
     */
    function nbTokens() external view returns (uint256) {
        return tokens.length;
    }

    /**
     * @return All the tokens registered in the bank.
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @return The internal token at a given index
     * @param index The index to look up in the bank's array of internal tokens
     */
    function getInternalToken(uint256 index) external view returns (address) {
        return internalTokens[index];
    }

    /**
     * @return The amount of internal token addresses in the bank
     */
    function nbInternalTokens() external view returns (uint256) {
        return internalTokens.length;
    }

    function addToBalance(
        address,
        address,
        uint256
    ) external payable {
        revert('not implemented');
    }

    /**
     * @notice Adds to a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function addToBalance(
        DaoRegistry dao,
        address member,
        address token,
        uint256 amount
    ) public payable hasExtensionAccess(dao, AclFlag.ADD_TO_BALANCE) {
        require(
            availableTokens[token] || availableInternalTokens[token],
            'unknown token address'
        );
        uint256 newAmount = balanceOf(member, token) + amount;
        uint256 newTotalAmount = balanceOf(DaoLibrary.TOTAL, token) + amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(DaoLibrary.TOTAL, token, newTotalAmount);
    }

    function addToBalanceBatch(
        DaoRegistry dao,
        address[] memory member ,
        address token,
        uint256[] memory amount
    ) public payable hasExtensionAccess(dao, AclFlag.ADD_TO_BALANCE) {
        require(
            availableTokens[token] || availableInternalTokens[token],
            'unknown token address'
        );
        for(uint256 i;i<member.length;i++){
            uint256 newAmount = balanceOf(member[i], token) + amount[i];
            uint256 newTotalAmount = balanceOf(DaoLibrary.TOTAL, token) + amount[i];
            _createNewAmountCheckpoint(member[i], token, newAmount);
            _createNewAmountCheckpoint(DaoLibrary.TOTAL, token, newTotalAmount);
        }

    }
    /**
     * @notice Remove from a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function subtractFromBalance(
        DaoRegistry dao,
        address member,
        address token,
        uint256 amount
    ) public hasExtensionAccess(dao, AclFlag.SUB_FROM_BALANCE) {
        uint256 newAmount = balanceOf(member, token) - amount;
        uint256 newTotalAmount = balanceOf(DaoLibrary.TOTAL, token) - amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(DaoLibrary.TOTAL, token, newTotalAmount);
    }

    function subtractFromBalance(
        address,
        address,
        uint256
    ) external pure {
        revert('not implemented');
    }

    function internalTransfer(
        address,
        address,
        address,
        uint256
    ) external pure {
        revert('not implemented');
    }

    /**
     * @notice Make an internal token transfer
     * @param from The member who is sending tokens
     * @param to The member who is receiving tokens
     * @param amount The new amount to transfer
     */
    function internalTransfer(
        DaoRegistry dao,
        address from,
        address to,
        address token,
        uint256 amount
    ) external hasExtensionAccess(dao, AclFlag.INTERNAL_TRANSFER) {
        require(_dao.notJailed(from), 'no transfer from jail');
        require(_dao.notJailed(to), 'no transfer from jail');
        uint256 newAmount = balanceOf(from, token) - amount;
        uint256 newAmount2 = balanceOf(to, token) + amount;

        _createNewAmountCheckpoint(from, token, newAmount);
        _createNewAmountCheckpoint(to, token, newAmount2);
    }

    /**
     * @notice Returns an member's balance of a given token
     * @param member The address to look up
     * @param tokenAddr The token where the member's balance of which will be returned
     * @return The amount in account's tokenAddr balance
     */
    function balanceOf(address member, address tokenAddr)
        public
        view
        returns (uint160)
    {
        uint32 nCheckpoints = numCheckpoints[tokenAddr][member];
        return
            nCheckpoints > 0
                ? checkpoints[tokenAddr][member][nCheckpoints - 1].amount
                : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorAmount(
        address account,
        address tokenAddr,
        uint256 blockNumber
    ) external view returns (uint256) {
        require(
            blockNumber < block.number,
            'bank::getPriorAmount: not yet determined'
        );

        uint32 nCheckpoints = numCheckpoints[tokenAddr][account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (
            checkpoints[tokenAddr][account][nCheckpoints - 1].fromBlock <=
            blockNumber
        ) {
            return checkpoints[tokenAddr][account][nCheckpoints - 1].amount;
        }

        // Next check implicit zero balance
        if (checkpoints[tokenAddr][account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenAddr][account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.amount;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[tokenAddr][account][lower].amount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            this.withdrawTo.selector == interfaceId;
    }

    /**
     * @notice Creates a new amount checkpoint for a token of a certain member
     * @dev Reverts if the amount is greater than 2**64-1
     * @param member The member whose checkpoints will be added to
     * @param token The token of which the balance will be changed
     * @param amount The amount to be written into the new checkpoint
     */
    function _createNewAmountCheckpoint(
        address member,
        address token,
        uint256 amount
    ) internal {
        bool isValidToken = false;
        if (availableInternalTokens[token]) {
            require(
                amount < type(uint88).max,
                'token amount exceeds the maximum limit for internal tokens'
            );
            isValidToken = true;
        } else if (availableTokens[token]) {
            require(
                amount < type(uint160).max,
                'token amount exceeds the maximum limit for external tokens'
            );
            isValidToken = true;
        }
        uint160 newAmount = uint160(amount);

        require(isValidToken, 'token not registered');

        uint32 nCheckpoints = numCheckpoints[token][member];
        if (
            // The only condition that we should allow the amount update
            // is when the block.number exactly matches the fromBlock value.
            // Anything different from that should generate a new checkpoint.
            //slither-disable-next-line incorrect-equality
            nCheckpoints > 0 &&
            checkpoints[token][member][nCheckpoints - 1].fromBlock ==
            block.number
        ) {
            checkpoints[token][member][nCheckpoints - 1].amount = newAmount;
        } else {
            checkpoints[token][member][nCheckpoints] = Checkpoint(
                uint96(block.number),
                newAmount
            );
            numCheckpoints[token][member] = nCheckpoints + 1;
        }
        //slither-disable-next-line reentrancy-events
        emit NewBalance(member, token, newAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";

interface IManagerAdapter {
    
    enum UpdateType {
        UNKNOWN,
        ADAPTER,
        EXTENSION
    }

    enum ConfigType {
        NUMERIC,
        ADDRESS
    }

    struct Configuration {
        ConfigType configType;
        bytes32 key;
        uint256 numericValue;
        address addressValue;
    }

    struct ManagerProposal {
        Foundance.ProposalStatus status;
        UpdateType updateType;
        bytes32 adapterOrExtensionId;
        address adapterOrExtensionAddr;
        uint128 flags;
        bytes32[] keys;
        uint256[] values;
        address[] extensionAddresses;
        uint128[] extensionAclFlags;
        Configuration[] configuration;
    }

    struct ManagerConfigurationProposal {
        Foundance.ProposalStatus status;
        Configuration[] configuration;
    }

    function submitManagerProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        ManagerProposal calldata proposal
    ) external;

    function submitManagerConfigurationProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Configuration[] calldata configuration
    ) external;

    function processManagerProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processManagerConfigurationProposal(DaoRegistry dao, bytes32 proposalId) external;
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";

interface IVotingAdapter {


    function getAdapterName() external pure returns (string memory);

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        string memory origin
    ) external;

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        string memory origin,
        Foundance.VotingType
    ) external;
    
    function getSenderAddress(
        DaoRegistry dao,
        address actionId,
        bytes memory data,
        address sender
    ) external returns (address);

    function voteResult(
        DaoRegistry dao, 
        bytes32 proposalId
    ) external returns (Foundance.VotingState state);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";
import "../interfaces/IReimbursement.sol";
import "../libraries/ReimbursableLibrary.sol";

abstract contract Reimbursable {
    struct ReimbursementData {
        uint256 gasStart; // how much gas is left before executing anything
        bool shouldReimburse; // should the transaction be reimbursed or not ?
        uint256 spendLimitPeriod; // how long (in seconds) is the spend limit period
        IReimbursement reimbursement; // which adapter address is used for reimbursement
    }

    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier reimbursable(DaoRegistry dao) {
        ReimbursementData memory data = ReimbursableLibrary.beforeExecution(dao);
        _;
        ReimbursableLibrary.afterExecution(dao, data);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "./Foundance.sol";
import "../core/DaoRegistry.sol";
import "../adapters/interfaces/IVotingAdapter.sol";
import "./DaoLibrary.sol";

library VotingAdapterLibrary {
    
    //SUBMIT
    function _submitProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        string memory origin
    ) internal {
        dao.submitProposal(proposalId);
        IVotingAdapter votingAdapter = IVotingAdapter(
            dao.getAdapterAddress(DaoLibrary.VOTING_ADPT)
        );
        address submittedBy = votingAdapter.getSenderAddress(
            dao,
            address(this),
            data,
            msg.sender
        );
        dao.sponsorProposal(proposalId, submittedBy, address(votingAdapter));
        votingAdapter.startNewVotingForProposal(dao, proposalId, data, origin);
    }

    function _submitProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        string memory origin,
        Foundance.VotingType votingType
    ) internal {
        dao.submitProposal(proposalId);
        IVotingAdapter votingAdapter = IVotingAdapter(
            dao.getAdapterAddress(DaoLibrary.VOTING_ADPT)
        );
        address submittedBy = votingAdapter.getSenderAddress(
            dao,
            address(this),
            data,
            msg.sender
        );
        dao.sponsorProposal(proposalId, submittedBy, address(votingAdapter));
        votingAdapter.startNewVotingForProposal(dao, proposalId, data, origin, votingType);
    }

    //PROCESS
    function _processProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) internal returns (Foundance.ProposalStatus){
        dao.processProposal(proposalId);
        IVotingAdapter votingAdapter = IVotingAdapter(dao.votingAdapter(proposalId));
        require(address(votingAdapter) != address(0), "votingAdpt::adapter not found");
        Foundance.VotingState voteResult = votingAdapter.voteResult(
            dao,
            proposalId
        );
        if (voteResult == Foundance.VotingState.PASS) {
            return Foundance.ProposalStatus.IN_PROGRESS;
        } else if (voteResult == Foundance.VotingState.NOT_PASS || voteResult == Foundance.VotingState.TIE) {
            return Foundance.ProposalStatus.FAILED;
        }else{
            return Foundance.ProposalStatus.NOT_STARTED;
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";

interface IReimbursement {
    function reimburseTransaction(
        DaoRegistry dao,
        address payable caller,
        uint256 gasUsage,
        uint256 spendLimitPeriod
    ) external;

    function shouldReimburse(DaoRegistry dao, uint256 gasLeft)
        external
        view
        returns (bool, uint256);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";
import "../interfaces/IReimbursement.sol";
import "../modifiers/Reimbursable.sol";


library ReimbursableLibrary {
    function beforeExecution(DaoRegistry dao)
        internal
        returns (Reimbursable.ReimbursementData memory data)
    {
        data.gasStart = gasleft();
        require(dao.lockedAt() != block.number, "reentrancy guard");
        dao.lockSession();
        address reimbursementAdapter = dao.adapters(DaoLibrary.REIMBURSEMENT_ADPT);
        if (reimbursementAdapter == address(0x0)) {
            data.shouldReimburse = false;
        } else {
            data.reimbursement = IReimbursement(reimbursementAdapter);

            (bool shouldReimburse, uint256 spendLimitPeriod) = data
                .reimbursement
                .shouldReimburse(dao, data.gasStart);

            data.shouldReimburse = shouldReimburse;
            data.spendLimitPeriod = spendLimitPeriod;
        }
    }

    function afterExecution(
        DaoRegistry dao,
        Reimbursable.ReimbursementData memory data
    ) internal {
        afterExecution2(dao, data, payable(msg.sender));
    }

    function afterExecution2(
        DaoRegistry dao,
        Reimbursable.ReimbursementData memory data,
        address payable caller
    ) internal {
        if (data.shouldReimburse) {
            data.reimbursement.reimburseTransaction(
                dao,
                caller,
                data.gasStart - gasleft(),
                data.spendLimitPeriod
            );
        }
        dao.unlockSession();
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// SPDX-License-Identifier: MIT
import "./DaoLibrary.sol";
import "../core/DaoRegistry.sol";
import "../extensions/BankExtension.sol";
import "../extensions/ERC20Extension.sol";


library GovernanceLibrary {
    string public constant ROLE_PREFIX = "governance.role.";
    bytes32 public constant DEFAULT_GOV_TOKEN_CFG =
        keccak256(abi.encodePacked(ROLE_PREFIX, "default"));

    /*
     * @dev Checks if the member address holds enough funds to be considered a governor.
     * @param dao The DAO Address.
     * @param memberAddr The message sender to be verified as governor.
     * @param proposalId The proposal id to retrieve the governance token address if configured.
     * @param snapshot The snapshot id to check the balance of the governance token for that member configured.
     */
    function getVotingWeight(
        DaoRegistry dao,
        address voterAddr,
        bytes32 proposalId,
        uint256 snapshot
    ) internal view returns (uint256) {
        (address adapterAddress, ) = dao.proposals(proposalId);

        // 1st - if there is any governance token configuration
        // for the adapter address, then read the voting weight based on that token.
        address governanceToken = dao.getAddressConfiguration(
            keccak256(abi.encodePacked(ROLE_PREFIX, adapterAddress))
        );
        if (DaoLibrary.isNotZeroAddress(governanceToken)) {
            return getVotingWeight(dao, governanceToken, voterAddr, snapshot);
        }

        // 2nd - if there is no governance token configured for the adapter,
        // then check if exists a default governance token.
        // If so, then read the voting weight based on that token.
        governanceToken = dao.getAddressConfiguration(DEFAULT_GOV_TOKEN_CFG);
        if (DaoLibrary.isNotZeroAddress(governanceToken)) {
            return getVotingWeight(dao, governanceToken, voterAddr, snapshot);
        }

        // 3rd - if none of the previous options are available, assume the
        // governance token is UNITS, then read the voting weight based on that token.
        return
            BankExtension(dao.getExtensionAddress(DaoLibrary.BANK_EXT))
                .getPriorAmount(voterAddr, DaoLibrary.UNITS, snapshot);
    }

    function getVotingWeight(
        DaoRegistry dao,
        address governanceToken,
        address voterAddr,
        uint256 snapshot
    ) internal view returns (uint256) {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        if (bank.isInternalToken(governanceToken)) {
            return bank.getPriorAmount(voterAddr, governanceToken, snapshot);
        }

        // The external token must implement the getPriorAmount function,
        // otherwise this call will fail and revert the voting process.
        // The actual revert does not show a clear reason, so we catch the error
        // and revert with a better error message.
        // slither-disable-next-line unused-return
        try
            ERC20Extension(governanceToken).getPriorAmount(voterAddr, snapshot)
        returns (
            // slither-disable-next-line uninitialized-local,variable-scope
            uint256 votingWeight
        ) {
            return votingWeight;
        } catch {
            revert("getPriorAmount not implemented");
        }
    }

    function calc(
        uint256 balance,
        uint256 units,
        uint256 totalUnits
    ) internal pure returns (uint256) {
        require(totalUnits > 0, "totalUnits must be greater than 0");
        require(
            units <= totalUnits,
            "units must be less than or equal to totalUnits"
        );
        if (balance == 0) {
            return 0;
        }
        // The balance for Internal and External tokens are limited to 2^64-1 (see Bank.sol:L411-L421)
        // The maximum number of units is limited to 2^64-1 (see ...)
        // Worst case cenario is: balance=2^64-1 * units=2^64-1, no overflows.
        uint256 prod = balance * units;
        return prod / totalUnits;
    }

}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import '../core/DaoRegistry.sol';
import "./BankExtension.sol";
import "../interfaces/IExtension.sol";
import "../adapters/interfaces/IERC20Adapter.sol";
import "../libraries/DaoLibrary.sol";
import "../modifiers/AdapterGuard.sol";

contract ERC20Extension is AdapterGuard, IExtension, IERC20 {


    // Internally tracks deployment under eip-1167 proxy pattern
    bool public initialized;
    // The DAO address that this extension belongs to
    DaoRegistry public _dao;





    
    // The token address managed by the DAO that tracks the internal transfers
    address public tokenAddress;
    // The name of the token managed by the DAO
    string public tokenName;
    // The symbol of the token managed by the DAO
    string public tokenSymbol;
    // The number of decimals of the token managed by the DAO
    uint8 public tokenDecimals;
    // Tracks all the token allowances: owner => spender => amount
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {}

    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "already initialized");
        require(tokenAddress != address(0x0), "missing token address");
        require(bytes(tokenName).length != 0, "missing token name");
        require(bytes(tokenSymbol).length != 0, "missing token symbol");
        initialized = true;
        _dao = dao;
    }

    //SET
    /**
     * @dev Returns the token address managed by the DAO that tracks the
     * internal transfers.
     */
    function token() external view virtual returns (address) {
        return tokenAddress;
    }

    /**
     * @dev Sets the token address if the extension is not initialized,
     * not reserved and not zero.
     */
    function setToken(address _tokenAddress) external {
        require(!initialized, "already initialized");
        require(_tokenAddress != address(0x0), "invalid token address");
        require(
            DaoLibrary.isNotReservedAddress(_tokenAddress),
            "token address already in use"
        );

        tokenAddress = _tokenAddress;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return tokenName;
    }

    /**
     * @dev Sets the name of the token if the extension is not initialized.
     */
    function setName(string memory _name) external {
        require(!initialized, "already initialized");
        tokenName = _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @dev Sets the token symbol if the extension is not initialized.
     */
    function setSymbol(string memory _symbol) external {
        require(!initialized, "already initialized");
        tokenSymbol = _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() external view virtual returns (uint8) {
        return tokenDecimals;
    }

    /**
     * @dev Sets the token decimals if the extension is not initialized.
     */
    function setDecimals(uint8 _decimals) external {
        require(!initialized, "already initialized");
        tokenDecimals = _decimals;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        BankExtension bank = BankExtension(
            _dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        return bank.balanceOf(DaoLibrary.TOTAL, tokenAddress);
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        BankExtension bank = BankExtension(
            _dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        return bank.balanceOf(account, tokenAddress);
    }

    /**
     * @dev Returns the amount of tokens owned by `account` considering the snapshot.
     */
    function getPriorAmount(address account, uint256 snapshot)
        external
        view
        returns (uint256)
    {
        BankExtension bank = BankExtension(
            _dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        return bank.getPriorAmount(account, tokenAddress, snapshot);
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @param spender The address account that will have the units decremented.
     * @param amount The amount to decrement from the spender account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    // slither-disable-next-line reentrancy-benign
    function approve(address spender, uint256 amount)
        public
        override
        reentrancyGuard(_dao)
        returns (bool)
    {
        address senderAddr = _dao.getAddressIfDelegated(msg.sender);
        require(
            DaoLibrary.isNotZeroAddress(senderAddr),
            "ERC20: approve from the zero address"
        );
        require(
            DaoLibrary.isNotZeroAddress(spender),
            "ERC20: approve to the zero address"
        );
        require(_dao.isMember(senderAddr), "sender is not a member");
        require(
            DaoLibrary.isNotReservedAddress(spender),
            "spender can not be a reserved address"
        );

        _allowances[senderAddr][spender] = amount;
        // slither-disable-next-line reentrancy-events
        emit Approval(senderAddr, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * @dev The transfer operation follows the DAO configuration specified
     * by the ERC20_EXT_TRANSFER_TYPE property.
     * @param recipient The address account that will have the units incremented.
     * @param amount The amount to increment in the recipient account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        return
            transferFrom(
                _dao.getAddressIfDelegated(msg.sender),
                recipient,
                amount
            );
    }

    function _transferInternal(
        address senderAddr,
        address recipient,
        uint256 amount,
        BankExtension bank
    ) internal {
        DaoLibrary.potentialNewMember(recipient, _dao, bank);
        bank.internalTransfer(_dao, senderAddr, recipient, tokenAddress, amount);
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * @dev The transfer operation follows the DAO configuration specified
     * by the ERC20_EXT_TRANSFER_TYPE property.
     * @param sender The address account that will have the units decremented.
     * @param recipient The address account that will have the units incremented.
     * @param amount The amount to decrement from the sender account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(
            DaoLibrary.isNotZeroAddress(recipient),
            "ERC20: transfer to the zero address"
        );

        IERC20Adapter strategy = IERC20Adapter(
            _dao.getAdapterAddress(DaoLibrary.ERC20_ADPT)
        );

        (
            IERC20Adapter.ApprovalType approvalType,
            uint256 allowedAmount
        ) = strategy.evaluateTransfer(
                _dao,
                tokenAddress,
                sender,
                recipient,
                amount,
                msg.sender
            );

        BankExtension bank = BankExtension(
            _dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );

        if (approvalType == IERC20Adapter.ApprovalType.NONE) {
            revert("transfer not allowed");
        }

        if (approvalType == IERC20Adapter.ApprovalType.SPECIAL) {
            _transferInternal(sender, recipient, amount, bank);
            //slither-disable-next-line reentrancy-events
            emit Transfer(sender, recipient, amount);
            return true;
        }

        if (sender != msg.sender) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            //check if sender has approved msg.sender to spend amount
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );

            if (allowedAmount >= amount) {
                _allowances[sender][msg.sender] = currentAllowance - amount;
            }
        }

        if (allowedAmount >= amount) {
            _transferInternal(sender, recipient, amount, bank);
            //slither-disable-next-line reentrancy-events
            emit Transfer(sender, recipient, amount);
            return true;
        }

        return false;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";

interface IERC20Adapter {
      enum AclFlag {
        REGISTER_TRANSFER
    }
    enum ApprovalType {
        NONE,
        STANDARD,
        SPECIAL
    }

    function evaluateTransfer(
        DaoRegistry dao,
        address tokenAddr,
        address from,
        address to,
        uint256 amount,
        address caller
    ) external view returns (ApprovalType, uint256);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import "../core/DaoRegistry.sol";
import "../interfaces/IExtension.sol";
import "../libraries/DaoLibrary.sol";
import "../extensions/DynamicEquityExtension.sol";
import "../extensions/VestedEquityExtension.sol";
import "../extensions/CommunityEquityExtension.sol";

contract MemberExtension is IExtension {

    enum AclFlag {
        SET_MEMBER,
        REMOVE_MEMBER,
        ACT_MEMBER
    }

    bool public initialized;

    DaoRegistry private _dao;

    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            _dao == dao &&
                (address(this) == msg.sender ||
                    address(_dao) == msg.sender ||
                    !initialized ||
                    DaoLibrary.isInCreationModeAndHasAccess(_dao) ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "memberExt::accessDenied"
        );
        _;
    }

    Foundance.MemberConfig[] public memberConfig;
    mapping(address => uint) public memberIndex;

    constructor() {}

    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "memberExt::already initialized");
        initialized = true;
        _dao = dao;
    }

    //SET
    function setMember(
        DaoRegistry dao,
        Foundance.MemberConfig calldata _memberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_MEMBER) {
        require(
            DaoLibrary.isNotReservedAddress(_memberConfig.memberAddress),
            "memberExt:: memberAddress is reserved or 0"
        );
        uint length = memberConfig.length;
        if(memberIndex[_memberConfig.memberAddress]==0){
            memberIndex[_memberConfig.memberAddress]=length+1;
            memberConfig.push(_memberConfig);
            BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoLibrary.BANK_EXT)
            );
            DaoLibrary.potentialNewMember(
                _memberConfig.memberAddress,
                dao,
                bank
            );
            bank.addToBalance(
                dao,
                _memberConfig.memberAddress,
                DaoLibrary.UNITS,
                _memberConfig.initialAmount
            );
        }else{
            memberConfig[memberIndex[_memberConfig.memberAddress]-1] = _memberConfig;
        } 
    }

    function setMemberSetup(
        DaoRegistry dao,
        Foundance.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig,
        Foundance.VestedEquityMemberConfig calldata _vestedEquityMemberConfig,
        Foundance.CommunityEquityMemberConfig calldata _communityEquityMemberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_MEMBER) {
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT));
        dynamicEquity.setDynamicEquityMember(
            dao,
            _dynamicEquityMemberConfig
        );
        VestedEquityExtension vestedEquity = VestedEquityExtension(dao.getExtensionAddress(DaoLibrary.VESTED_EQUITY_EXT));
        vestedEquity.setVestedEquityMember(
            dao,
            _vestedEquityMemberConfig
        );
        CommunityEquityExtension communityEquity = CommunityEquityExtension(dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT));
        communityEquity.setCommunityEquityMember(
            dao,
            _communityEquityMemberConfig
        );
    }

    function setMemberAppreciationRight(
        DaoRegistry dao,
        address _memberAddress,
        bool appreciationRight
    ) external hasExtensionAccess(dao, AclFlag.SET_MEMBER) {
        require(memberIndex[_memberAddress]>0, "memberExt::member not set");
        Foundance.MemberConfig storage member = memberConfig[memberIndex[_memberAddress]-1];
        member.appreciationRight = appreciationRight;
    }

    function setMemberEnvironment(
        DaoRegistry dao,
        Foundance.DynamicEquityConfig memory _dynamicEquityConfig,
        Foundance.VestedEquityConfig memory _vestedEquityConfig,
        Foundance.CommunityEquityConfig memory _communityEquityConfig,
        Foundance.EpochConfig memory _epochConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_MEMBER) {
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT));
        VestedEquityExtension vestedEquity = VestedEquityExtension(dao.getExtensionAddress(DaoLibrary.VESTED_EQUITY_EXT));
        CommunityEquityExtension communityEquity = CommunityEquityExtension(dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT));
        dynamicEquity.setDynamicEquity(dao, _dynamicEquityConfig, _epochConfig);
        vestedEquity.setVestedEquity(dao, _vestedEquityConfig);
        communityEquity.setCommunityEquity(dao, _communityEquityConfig, _epochConfig);
    }

    //REMOVE
    function removeMember(
        DaoRegistry dao,
        address _memberAddress
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_MEMBER) {
        require(
            memberIndex[_memberAddress]>0,
            "memberExt::member not set"
        );
        memberIndex[_memberAddress]==0;
    }

    function removeMemberSetup(
        DaoRegistry dao,
        address _memberAddress
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_MEMBER) {
        require(
            memberIndex[_memberAddress]>0,
            "memberExt::member not set"
        );
        require(
            _memberAddress!=address(0),
            "memberExt::member not set"
        );
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT));
        dynamicEquity.removeDynamicEquityMember(
            dao,
            _memberAddress
        );
        CommunityEquityExtension communityEquity = CommunityEquityExtension(dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT));
        communityEquity.removeCommunityEquityMember(
            dao,
            _memberAddress
        );
        VestedEquityExtension vestedEquity = VestedEquityExtension(dao.getExtensionAddress(DaoLibrary.VESTED_EQUITY_EXT));
        vestedEquity.removeVestedEquityMember(
            dao,
            _memberAddress
        );
    }


    //GET
    function getIsMember(
        address _memberAddress
    ) external view returns (bool) {
        return memberConfig[memberIndex[_memberAddress]-1].memberAddress==address(0) ? true : false;
    }

    function getMemberConfig(
        address _memberAddress
    ) external view returns (Foundance.MemberConfig memory) {
        return memberConfig[memberIndex[_memberAddress]-1];
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";

interface IMemberAdapter {

    //SUBMIT
    function submitSetMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.MemberConfig memory _memberConfig
    ) external;

    function submitSetMemberSetupProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.MemberConfig memory _memberConfig,
        Foundance.DynamicEquityMemberConfig memory _dynamicEquityMemberConfig,
        Foundance.VestedEquityMemberConfig memory _vestedEquityMemberConfig,
        Foundance.CommunityEquityMemberConfig memory _communityEquityMemberConfig
    ) external;

    function submitRemoveMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external;
    
    //PROCESS
    function processSetMemberProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetMemberSetupProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveMemberProposal(DaoRegistry dao, bytes32 proposalId, bytes calldata data, bytes32 newProposalId) external;

    function processRemoveMemberBadLeaverProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveMemberResigneeProposal(DaoRegistry dao, bytes32 proposalId) external;

    //ACT
    function actMemberResign(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external;
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import '../core/DaoRegistry.sol';
import "../interfaces/IExtension.sol";
import "../libraries/DaoLibrary.sol";

contract DynamicEquityExtension is IExtension {

    enum AclFlag {
        SET_DYNAMIC_EQUITY,
        REMOVE_DYNAMIC_EQUITY,
        ACT_DYNAMIC_EQUITY
    }

    bool public initialized;

    DaoRegistry private _dao;

    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            _dao == dao &&
                (address(this) == msg.sender ||
                    address(_dao) == msg.sender ||
                    !initialized ||
                    DaoLibrary.isInCreationModeAndHasAccess(_dao) ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "dynamicEquityExt::accessDenied"
        );
        _;
    }

    Foundance.EpochConfig public epochConfig;
    Foundance.DynamicEquityConfig public dynamicEquityConfig;
    mapping(uint256 => mapping(address => Foundance.DynamicEquityMemberConfig)) public dynamicEquityEpochs;
    Foundance.DynamicEquityMemberConfig[] public dynamicEquityMemberConfig;
    mapping(address => uint) public dynamicEquityMemberIndex;

    constructor() {}

    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "dynamicEquityExt::already initialized");
        initialized = true;
        _dao = dao;
    }

    //SET 
    function setDynamicEquity(
        DaoRegistry dao,
        Foundance.DynamicEquityConfig calldata _dynamicEquityConfig,
        Foundance.EpochConfig calldata _epochConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        dynamicEquityConfig = _dynamicEquityConfig;
        epochConfig = _epochConfig;
        epochConfig.epochLast = epochConfig.epochStart;
    }

    function setDynamicEquityEpoch(
        DaoRegistry dao,
        uint256 newEpochLast
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        require(
            epochConfig.epochLast < block.timestamp,
            "dynamicEquityExt::epochLast required to be < block.timestamp"
        );
        require(
            epochConfig.epochLast < newEpochLast,
            "dynamicEquityExt::newEpochLast required to be > epochLast"
        );
        epochConfig.epochLast = newEpochLast;
    }

    function setDynamicEquityMember(
        DaoRegistry dao,
        Foundance.DynamicEquityMemberConfig memory _dynamicEquityMemberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        require(
            DaoLibrary.isNotReservedAddress(_dynamicEquityMemberConfig.memberAddress),
            "dynamicEquityExt:: memberAddress is reserved or 0"
        );
        _dynamicEquityMemberConfig.expense = 0;
        uint length = dynamicEquityMemberConfig.length;
        if(dynamicEquityMemberIndex[_dynamicEquityMemberConfig.memberAddress]==0){
            dynamicEquityMemberIndex[_dynamicEquityMemberConfig.memberAddress]=length+1;
            dynamicEquityMemberConfig.push(_dynamicEquityMemberConfig);
        }else{
            dynamicEquityMemberConfig[dynamicEquityMemberIndex[_dynamicEquityMemberConfig.memberAddress]-1] = _dynamicEquityMemberConfig;
        } 
    }

    function setDynamicEquityMemberBatch(
        DaoRegistry dao,
        Foundance.DynamicEquityMemberConfig[] memory _dynamicEquityMemberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        uint length = dynamicEquityMemberConfig.length;
        for(uint256 i=0; i < _dynamicEquityMemberConfig.length; i++){
            if(DaoLibrary.isNotReservedAddress(_dynamicEquityMemberConfig[i].memberAddress)){
                _dynamicEquityMemberConfig[i].expense = 0;
                if(dynamicEquityMemberIndex[_dynamicEquityMemberConfig[i].memberAddress]==0){
                    dynamicEquityMemberIndex[_dynamicEquityMemberConfig[i].memberAddress]=length+1;
                    dynamicEquityMemberConfig.push(_dynamicEquityMemberConfig[i]);
                }else{
                    dynamicEquityMemberConfig[dynamicEquityMemberIndex[_dynamicEquityMemberConfig[i].memberAddress]-1] = _dynamicEquityMemberConfig[i];
                } 
            }
        }
    }

    function setDynamicEquityMemberSuspend(
        DaoRegistry dao,
        address _member,
        uint256 suspendedUntil
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        require(
            dynamicEquityMemberIndex[_member]>0,
            "dynamicEquityExt::member not set"
        );
        dynamicEquityMemberConfig[dynamicEquityMemberIndex[_member]-1].suspendedUntil = suspendedUntil;
    }

    function setDynamicEquityMemberEpoch(
        DaoRegistry dao,
        Foundance.DynamicEquityMemberConfig calldata config
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        Foundance.DynamicEquityMemberConfig memory _dynamicEquityMemberConfig = dynamicEquityMemberConfig[dynamicEquityMemberIndex[config.memberAddress]-1];
        require(
            dynamicEquityMemberIndex[config.memberAddress] > 0,
            "dynamicEquityExt::member not set"
        );
        require(
            DaoLibrary.isNotReservedAddress(config.memberAddress),
            "dynamicEquityExt:: memberAddress is reserved or 0"
        );
        require(
            config.availability <= _dynamicEquityMemberConfig.availabilityThreshold,
            "dynamicEquityExt::availability out of bound"
        );
        require(
            config.expense <= _dynamicEquityMemberConfig.expenseThreshold,
            "dynamicEquityExt::expense out of bound"
        );
        uint256 expenseCommittedThreshold = _dynamicEquityMemberConfig.expenseCommitted * _dynamicEquityMemberConfig.expenseCommittedThreshold / 100;
        require(
            config.expenseCommitted <= _dynamicEquityMemberConfig.expenseCommitted + expenseCommittedThreshold &&
            config.expenseCommitted >= _dynamicEquityMemberConfig.expenseCommitted - expenseCommittedThreshold,
            "dynamicEquityExt::expenseCommitted out of bound"
        );
        uint256 withdrawalThreshold = _dynamicEquityMemberConfig.withdrawal * _dynamicEquityMemberConfig.withdrawalThreshold / 100;
        require(
            config.withdrawal <= _dynamicEquityMemberConfig.withdrawal + withdrawalThreshold &&
            config.withdrawal >= _dynamicEquityMemberConfig.withdrawal - withdrawalThreshold, 
            "dynamicEquityExt::withdrawal out of bound"
        );
        dynamicEquityEpochs[epochConfig.epochLast+epochConfig.epochDuration][config.memberAddress] = config;
    }

    //REMOVE
    function removeDynamicEquityMemberEpoch(
        DaoRegistry dao,
        address _member
    ) external hasExtensionAccess(dao, AclFlag.REMOVE_DYNAMIC_EQUITY) {
        require(
            dynamicEquityMemberIndex[_member]>0,
            "dynamicEquityExt::member not set"
        );
        Foundance.DynamicEquityMemberConfig storage _config = dynamicEquityEpochs[epochConfig.epochLast+epochConfig.epochDuration][_member];
        _config.memberAddress = address(0);
    }

    function removeDynamicEquityMember(
        DaoRegistry dao,
        address _member
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_DYNAMIC_EQUITY) {
        require(
            dynamicEquityMemberIndex[_member]>0,
            "dynamicEquityExt::member not set"
        );
        dynamicEquityMemberIndex[_member]==0;
    }

    //GET_INTERNAL
    function getDynamicEquityMemberEpochAmountInternal(
        Foundance.DynamicEquityMemberConfig memory dynamicEquityMemberEpochConfig
    ) internal view returns (uint) {
        uint timeEquity = 0;
        uint precisionFactor = 10**DaoLibrary.FOUNDANCE_PRECISION;
        uint salaryEpoch = dynamicEquityMemberEpochConfig.salary * dynamicEquityMemberEpochConfig.availability;
        if(salaryEpoch > dynamicEquityMemberEpochConfig.withdrawal){
            timeEquity = ((salaryEpoch - dynamicEquityMemberEpochConfig.withdrawal) * dynamicEquityConfig.timeMultiplier / precisionFactor);
        }
        uint riskEquity = ((dynamicEquityMemberEpochConfig.expense + dynamicEquityMemberEpochConfig.expenseCommitted) * dynamicEquityConfig.riskMultiplier / precisionFactor);
        return timeEquity + riskEquity;
    }

    //GET
    function getDynamicEquityMemberEpochAmount(
        address _member
    ) external view returns (uint) {
        Foundance.DynamicEquityMemberConfig memory _epochMemberConfig = dynamicEquityEpochs[epochConfig.epochLast][_member];
        if(_epochMemberConfig.memberAddress != address(0)){
            return getDynamicEquityMemberEpochAmountInternal(
                _epochMemberConfig
            );
        }else{
            return getDynamicEquityMemberEpochAmountInternal(
                dynamicEquityMemberConfig[dynamicEquityMemberIndex[_member]-1]
            );
        }
    }

    function getDynamicEquityMemberEpoch(
        address _member
    ) external view returns (Foundance.DynamicEquityMemberConfig memory) {
        return dynamicEquityEpochs[epochConfig.epochLast][_member];
    }

    function getDynamicEquityMemberEpoch(
        address _member,
        uint256 timestamp
    ) external view returns (Foundance.DynamicEquityMemberConfig memory) {
        return dynamicEquityEpochs[timestamp][_member];
    }

    function getEpochConfig(
    ) public view returns (Foundance.EpochConfig memory) {
        return epochConfig;
    }

    function getIsNotReviewPeriod(
        DaoRegistry dao
    ) public view returns (bool) {
        return true;
    }

    function getDynamicEquityConfig(
    ) public view returns (Foundance.DynamicEquityConfig memory) {
        return dynamicEquityConfig;
    }

    function getDynamicEquityMemberConfig(
    ) external view returns (Foundance.DynamicEquityMemberConfig[] memory) {
        return dynamicEquityMemberConfig;
    }

    function getDynamicEquityMemberConfig(
        address _member
    ) external view returns (Foundance.DynamicEquityMemberConfig memory) {
        return dynamicEquityMemberConfig[dynamicEquityMemberIndex[_member]-1];
    }

    function getDynamicEquityMemberSuspendedUntil(
        address _member
    ) external view returns (uint256 suspendedUntil) {
        return dynamicEquityMemberConfig[dynamicEquityMemberIndex[_member]-1].suspendedUntil;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import "../core/DaoRegistry.sol";
import "../interfaces/IExtension.sol";
import "../libraries/DaoLibrary.sol";

contract VestedEquityExtension is IExtension {

    enum AclFlag {
        SET_VESTED_EQUITY,
        REMOVE_VESTED_EQUITY,
        ACT_VESTED_EQUITY
    }

    bool public initialized;

    DaoRegistry private _dao;

    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            _dao == dao &&
                (address(this) == msg.sender ||
                    address(_dao) == msg.sender ||
                    !initialized ||
                    DaoLibrary.isInCreationModeAndHasAccess(_dao) ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "vestedEquityExt::accessDenied"
        );
        _;
    }

    Foundance.VestedEquityConfig public vestedEquityConfig;
    Foundance.VestedEquityMemberConfig[] public vestedEquityMemberConfig;
    mapping(address => uint) public vestedEquityMemberIndex;

    constructor() {}

    function initialize(DaoRegistry dao, address) external override {
        require(
            !initialized,
            "vestedEquityExt::already initialized"
        );
        initialized = true;
        _dao = dao;
    }

    //SET
    function setVestedEquity(
        DaoRegistry dao,
        Foundance.VestedEquityConfig calldata _vestedEquityConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_VESTED_EQUITY) {
        vestedEquityConfig = _vestedEquityConfig;
    }

    function setVestedEquityMember(
        DaoRegistry dao,
        Foundance.VestedEquityMemberConfig calldata _vestedEquityMemberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_VESTED_EQUITY) {
        require(
            DaoLibrary.isNotReservedAddress(_vestedEquityMemberConfig.memberAddress),
            "vestedEquityExt:: memberAddress is reserved or 0"
        );
        uint length = vestedEquityMemberConfig.length;
        if(vestedEquityMemberIndex[_vestedEquityMemberConfig.memberAddress]==0){
            vestedEquityMemberIndex[_vestedEquityMemberConfig.memberAddress]=length+1;
            vestedEquityMemberConfig.push(_vestedEquityMemberConfig);
        }else{
            vestedEquityMemberConfig[vestedEquityMemberIndex[_vestedEquityMemberConfig.memberAddress]-1] = _vestedEquityMemberConfig;
        } 
    }

    function setVestedEquityMemberBatch(
        DaoRegistry dao,
        Foundance.VestedEquityMemberConfig[] calldata _vestedEquityMemberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_VESTED_EQUITY) {
        for(uint256 i=0;i<_vestedEquityMemberConfig.length;i++){
            if(DaoLibrary.isNotReservedAddress(_vestedEquityMemberConfig[i].memberAddress)){
                uint length = vestedEquityMemberConfig.length;
                if(vestedEquityMemberIndex[_vestedEquityMemberConfig[i].memberAddress]==0){
                    vestedEquityMemberIndex[_vestedEquityMemberConfig[i].memberAddress]=length+1;
                    vestedEquityMemberConfig.push(_vestedEquityMemberConfig[i]);
                }else{
                    vestedEquityMemberConfig[vestedEquityMemberIndex[_vestedEquityMemberConfig[i].memberAddress]-1] = _vestedEquityMemberConfig[i];
                } 
            }
        }
    }

    //REMOVE
    function removeVestedEquityMember(
        DaoRegistry dao,
        address _member
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_VESTED_EQUITY) {
        require(
            vestedEquityMemberIndex[_member]>0,
            "vestedEquityExt::member not set"
        );
        vestedEquityMemberIndex[_member]==0;
    }

    function removeVestedEquityMemberAmount(
        DaoRegistry dao,
        address _member
    ) external hasExtensionAccess(dao, AclFlag.REMOVE_VESTED_EQUITY) {
        uint256 blockTimestamp = block.timestamp;
        Foundance.VestedEquityMemberConfig storage _vestedEquityMemberConfig = vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1];
        require(
            blockTimestamp > _vestedEquityMemberConfig.start + _vestedEquityMemberConfig.cliff,
            "vestedEquityExt::cliff not yet exceeded"
        );
        require(
            blockTimestamp > _vestedEquityMemberConfig.start + vestedEquityConfig.vestingCadenceInS,
            "vestedEquityExt::cadence not yet exceeded"
        );
        _vestedEquityMemberConfig.tokenAmount -= getVestedEquityMemberDistributionAmountInternal(_member);
        uint256 prolongedDuration = blockTimestamp - _vestedEquityMemberConfig.start;
        _vestedEquityMemberConfig.duration -= prolongedDuration;
        _vestedEquityMemberConfig.start = blockTimestamp;
        _vestedEquityMemberConfig.cliff = 0;
    }

    //GET_INTERNAL
    function getVestedEquityMemberDistributionAmountInternal(
        address _member
    ) internal view returns (uint) {
        uint256 blockTimestamp = block.timestamp;
        Foundance.VestedEquityMemberConfig storage _vestedEquityMemberConfig = vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1];
        uint256 amount = 0;
        if(blockTimestamp > _vestedEquityMemberConfig.start + _vestedEquityMemberConfig.cliff){
            if(_vestedEquityMemberConfig.start + _vestedEquityMemberConfig.duration > blockTimestamp){
                uint256 prolongedDuration = blockTimestamp - _vestedEquityMemberConfig.start;
                uint256 precisionFactor = 1000000;
                uint256 toBeDistributed = (prolongedDuration * precisionFactor / _vestedEquityMemberConfig.duration) * _vestedEquityMemberConfig.tokenAmount / precisionFactor;
                return toBeDistributed < _vestedEquityMemberConfig.tokenAmount ? toBeDistributed : _vestedEquityMemberConfig.tokenAmount;
            }else{
                return _vestedEquityMemberConfig.tokenAmount;
            }
        }
        return amount;
    }

    //GET
    function getVestedEquityMemberConfig(
    ) external view returns (Foundance.VestedEquityMemberConfig[] memory) {
        return vestedEquityMemberConfig;
    }

    function getVestedEquityMemberConfig(
        address _member
    ) external view returns (Foundance.VestedEquityMemberConfig memory) {
        return vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1];
    }

    function getVestedEquityMemberAmount(
        address _member
    ) external view returns (uint) {
        return vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1].tokenAmount;
    }

    function getVestedEquityMemberDistributionAmount(
        address _member
    ) external view returns (uint) {
        return getVestedEquityMemberDistributionAmountInternal(_member);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import '../core/DaoRegistry.sol';
import "../interfaces/IExtension.sol";
import "../libraries/DaoLibrary.sol";

contract CommunityEquityExtension is IExtension {

    enum AclFlag {
        SET_COMMUNITY_EQUITY,
        REMOVE_COMMUNITY_EQUITY,
        ACT_COMMUNITY_EQUITY
    }

    bool public initialized;

    DaoRegistry private _dao;
    
    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            _dao == dao &&
                (address(this) == msg.sender ||
                    address(_dao) == msg.sender ||
                    !initialized ||
                    DaoLibrary.isInCreationModeAndHasAccess(_dao) ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "communityEquity::accessDenied"
        );
        _;
    }

    Foundance.EpochConfig public epochConfig;
    Foundance.CommunityEquityConfig public communityEquityConfig;
    Foundance.CommunityEquityMemberConfig[] public communityEquityMemberConfig;
    mapping(address => uint) public communityEquityMemberIndex;

    constructor() {}
    
    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "communityEquity::already initialized");
        initialized = true;
        _dao = dao;
    }

    //SET
    function setCommunityEquity(
        DaoRegistry dao,
        Foundance.CommunityEquityConfig calldata _communityEquityConfig 
    ) external hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_EQUITY) {
        communityEquityConfig = _communityEquityConfig;
    }

    function setCommunityEquity(
        DaoRegistry dao,
        Foundance.CommunityEquityConfig calldata _communityEquityConfig, 
        Foundance.EpochConfig calldata _epochConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_EQUITY) {
        communityEquityConfig = _communityEquityConfig;
        epochConfig = _epochConfig;
        epochConfig.epochLast = epochConfig.epochStart;
    }

    function setCommunityEquityEpoch(
        DaoRegistry dao
    ) external hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_EQUITY) {
        require(
            communityEquityConfig.allocationType==Foundance.AllocationType.EPOCH,
            "communityEquityExt::AllocationType has to be EPOCH"
        );
        //TODO replenish tokenAmount
        //TODO update epoch
    }

    function setCommunityEquityMember(
        DaoRegistry dao,
        Foundance.CommunityEquityMemberConfig calldata _communityEquityMemberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_EQUITY) {
        require(
            DaoLibrary.isNotReservedAddress(_communityEquityMemberConfig.memberAddress),
            "communityEquityExt:: memberAddress is reserved or 0"
        );
        uint length = communityEquityMemberConfig.length;
        if(communityEquityMemberIndex[_communityEquityMemberConfig.memberAddress]==0){
            communityEquityMemberIndex[_communityEquityMemberConfig.memberAddress]=length+1;
            communityEquityMemberConfig.push(_communityEquityMemberConfig);
        }else{
            communityEquityMemberConfig[communityEquityMemberIndex[_communityEquityMemberConfig.memberAddress]-1] = _communityEquityMemberConfig;
        } 
    }

    function setCommunityEquityMemberBatch(
        DaoRegistry dao,
        Foundance.CommunityEquityMemberConfig[] calldata _communityEquityMemberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_EQUITY) {
        for(uint256 i=0;i<_communityEquityMemberConfig.length;i++){
            if(DaoLibrary.isNotReservedAddress(_communityEquityMemberConfig[i].memberAddress)){
                uint length = communityEquityMemberConfig.length;
                if(communityEquityMemberIndex[_communityEquityMemberConfig[i].memberAddress]==0){
                    communityEquityMemberIndex[_communityEquityMemberConfig[i].memberAddress]=length+1;
                    communityEquityMemberConfig.push(_communityEquityMemberConfig[i]);
                }else{
                    communityEquityMemberConfig[communityEquityMemberIndex[_communityEquityMemberConfig[i].memberAddress]-1] = _communityEquityMemberConfig[i];
                } 
            }
        }
    }

    //REMOVE
    function removeCommunityEquity(
        DaoRegistry dao
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_COMMUNITY_EQUITY) {
        //TODO remove config
        //TODO remove epoch
        //TODO remove configMemberIndex//allmember
    }

    function removeCommunityEquityMember(
        DaoRegistry dao,
        address _member
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_COMMUNITY_EQUITY) {
        require(communityEquityMemberIndex[_member]>0, "communityEquity::member not set");
        communityEquityMemberIndex[_member]==0;
    }
    
    //GET
    function getCommunityEquityEpochConfig(
    ) public view returns (Foundance.EpochConfig memory) {
        return epochConfig;
    }

    function getCommunityEquityConfig(
    ) public view returns (Foundance.CommunityEquityConfig memory) {
        return communityEquityConfig;
    }

    function getCommunityEquityMemberConfig(
    ) external view returns (Foundance.CommunityEquityMemberConfig[] memory) {
        return communityEquityMemberConfig;
    }

    function getIsCommunityEquityMember(
        address _memberAddress
    ) external view returns (bool) {
        return communityEquityMemberConfig[communityEquityMemberIndex[_memberAddress]-1].memberAddress==address(0) ? true : false;
    }

    function getCommunityEquityMemberConfig(
        address _member
    ) external view returns (Foundance.CommunityEquityMemberConfig memory) {
        return communityEquityMemberConfig[communityEquityMemberIndex[_member]-1];
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";

interface IDynamicEquity {

    //SUBMIT
    function submitSetDynamicEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityConfig calldata _dynamicEquityConfig,
        Foundance.EpochConfig calldata _epochConfig
    ) external;

    function submitSetDynamicEquityEpochProposal( 
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        uint256 _lastEpoch
    ) external;

    function submitSetDynamicEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig
    ) external;

    function submitSetDynamicEquityMemberSuspendProposal( 
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress,
        uint256 _suspendUntil
    ) external;

    function submitSetDynamicEquityMemberEpochProposal( 
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig
    ) external;

    function submitSetDynamicEquityMemberEpochExpenseProposal( 
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress,
        uint256 _expenseAmount
    ) external;

    function submitRemoveDynamicEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress
    ) external;

    function submitRemoveDynamicEquityMemberEpochProposal( 
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress
    ) external;

    //PROCESS
    function processSetDynamicEquityProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetDynamicEquityEpochProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetDynamicEquityMemberProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetDynamicEquityMemberSuspendProposal(DaoRegistry dao, bytes32 proposalId) external;
    
    function processSetDynamicEquityMemberEpochProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetDynamicEquityMemberEpochExpenseProposal(DaoRegistry dao, bytes32 proposalId, uint256 _expenseAmount) external;

    function processRemoveDynamicEquityMemberProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveDynamicEquityMemberEpochProposal(DaoRegistry dao, bytes32 proposalId) external;

    //ACT
    function actDynamicEquityEpochDistributed(
        DaoRegistry dao
    ) external; 
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";

interface IVestedEquity {

    //SUBMIT
    function submitSetVestedEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.VestedEquityMemberConfig calldata _vestedEquityMemberConfig
    ) external;
    
    function submitRemoveVestedEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress
    ) external;

    //PROCESS
    function processSetVestedEquityMemberProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveVestedEquityMemberProposal(DaoRegistry dao, bytes32 proposalId) external;
    
    //ACT
    function actVestedEquityMemberDistributed(
        DaoRegistry dao,
        address _memberAddress
    ) external;
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";

interface ICommunityEquity {

    //SUBMIT
    function submitSetCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.CommunityEquityConfig calldata _communityEquityConfig,
        Foundance.EpochConfig calldata _epochConfig
    ) external;

    function submitSetCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.CommunityEquityMemberConfig calldata _communityEquityMemberConfig
    ) external;

    function submitRemoveCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data
    ) external;

    function submitRemoveCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external;
        
    //PROCESS
    function processSetCommunityEquityProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetCommunityEquityMemberProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveCommunityEquityProposal(DaoRegistry dao, bytes32 proposalId) external; 

    function processRemoveCommunityEquityMemberProposal(DaoRegistry dao, bytes32 proposalId) external;  

    //ACT
    function actCommunityEquityMemberDistributed(
        DaoRegistry dao,
        address _memberAddress,
        uint256 _amountToBeSent,
        bytes32 _distributionId 
    ) external;

    function actCommunityEquityEpochDistributed(
        DaoRegistry dao
    ) external;  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";

interface IFactory {
    /**
     * @notice Do not rely on the result returned by this right after the new extension is cloned,
     * because it is prone to front-running attacks. During the extension creation it is safer to
     * read the new extension address from the event generated in the create call transaction.
     */
    function getExtensionAddress(address dao) external view returns (address);
}