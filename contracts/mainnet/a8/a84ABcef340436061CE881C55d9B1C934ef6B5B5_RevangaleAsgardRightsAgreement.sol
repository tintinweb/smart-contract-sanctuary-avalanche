/**
 *Submitted for verification at snowtrace.io on 2022-03-16
*/

/// @author Asgard GameFi - A Metaverse Built for the Gods
/// @notice Subject to the terms and conditions set forth in the Agreement.

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.12;

contract RevangaleAsgardRightsAgreement {
  constructor() {}

  address public odinOdinson = 0x3ad6A0856019Cb00191CEf956686332544291097;
  address public revangale = 0x361d1601a9d4628DFEA195024b5E443431A49105;

  mapping(address => bool) public signatures;

  modifier onlyAgreementSigners() {
    require(msg.sender == odinOdinson || msg.sender == revangale, "Signer is not correct address");
    _;
  }

  function signAgreement() external onlyAgreementSigners {
    signatures[msg.sender] = true;
  }
}

/// @notice EXCLUSIVE LICENSE AGREEMENT

/*
This License Agreement (“Agreement”) is entered into by and between Licensor, Revangale and Licensee Asgard GameFi (“Asgard”). 

WHEREAS, the Art (as defined below) was developed by Revangale and 
WHEREAS, Asgard wishes to obtain an exclusive license to the Art; and

NOW, THEREFORE, the parties hereby agree as follows: 

1. Definitions. 
Whenever used in this Agreement with an initial capital letter, the terms defined in this Article 1, whether used in the singular or the plural, will have the meanings specified below. 
1.1 “Derivative Works” means any work based on or derived from any Art licensed to Asgard.
1.2 “Licensed Product” means any program, product or service that incorporates or makes use of the Art or Derivative Works, in whole or in part. 
1.3 “Art” means the original collective artwork(s) known as “Midgardians NFTs” which includes the male base, female base, all articles of clothing, features, backgrounds, and accessories represented in the collection (See exhibit 1 for example) and “Midgard Online Assets”.

2 Ownership and License Grants. 
2.1 Ownership of Art and Derivative Works. The parties agree and acknowledge that Asgard owns all rights, title and interest in and to the Art and its derivative works.
2.3 License Grant to Art. Subject to the terms and conditions set forth in this Agreement, Revangale hereby grants Asgard an exclusive, royalty-free, worldwide license to use, execute, reproduce, modify, display, perform, transmit, distribute internally or externally, sell, and prepare the Art and its derivative works. 
2.4 License Grant to Derivative Works. Revangale hereby grants to Asgard an exclusive, royalty- free license to use, execute, reproduce, modify, display, perform, transmit, distribute internally or externally and prepare derivative works of the Derivative Works.

3. Consideration for Grant of License. 
3.1 Payment. As consideration for the exclusive license granted, Revangale has been given payment from Asgard.

4. No Warranty. 
4.1 Nothing contained herein shall be deemed to be a warranty by Asgard.

5. Miscellaneous. 
5.1 Use of Name. Revangale shall not use or register the name “Asgard” (alone or as part of another name) or any logos, seals, insignia or other words, names, symbols or devices that identify Asgard or any unit, division or affiliate (“Asgard Names”) for any purpose except with the prior written approval of, and in accordance with restrictions required by, Asgard. 
5.2 Entire Agreement. This Agreement is the sole agreement with respect to the subject matter hereof and except as expressly set forth herein, supersedes all other agreements and understandings between the parties with respect to the same. 
5.3 Notices. Unless otherwise specifically provided, all notices required or permitted by this Agreement shall be by electronic correspondence.
5.4 Binding Effect. This Agreement shall be binding upon and inure to the benefit of the parties and their respective legal representatives, successors and permitted assigns. 
5.4 No Agency or Partnership. Nothing contained in this Agreement shall give either party the right to bind the other, or be deemed to constitute either party as agent for or partner of the other or any third party. 
5.5 Assignment and Successors. This Agreement may not be assigned by either party without the consent of the other. 
5.6 Severability. If any provision of this Agreement is or becomes invalid or is ruled invalid by any court of competent jurisdiction or is deemed unenforceable, it is the intention of the parties that the remainder of this Agreement shall not be affected.

IN WITNESS WHEREOF, the parties have caused this Agreement to be executed by their duly authorized representatives as of the date first written above. 
*/