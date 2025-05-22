// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <= 0.9.0;

// Contract for an e-voting system
contract EVoting {
    // Structure for a candidate in the election
    struct Candidate {
        uint id;
        string firstName;
        string lastName;
        string candidateID;
        string politicalParty;
        uint voteCount; // to keep track of the votes each candidate receives
    }
    // Structure for an election`
    struct Election {
        bool isActive; // flag to check if the election is active
        mapping(uint => Candidate) candidates; // mapping of candidate IDs to candidate details
        uint[] candidateIds; // array to store candidate IDs
    }

    address[] public admin; // Array to store admin addresses
    mapping(address => bool) public isAnAdmin;
    mapping(uint => Election) public elections;
    uint public adminCount; // Count of total admins
    uint public nextElectionId;
    // Mapping to track if a user has voted in a specific election
    mapping(address => mapping(uint => bool)) public hasVoted;

    // Constructor to initialize admin addresses
    constructor(address[] memory initialAdmins) {
        for (uint i = 0; i < initialAdmins.length; i++) {
            admin.push(initialAdmins[i]);
            isAnAdmin[initialAdmins[i]] = true;
        }
        adminCount = initialAdmins.length;
    }
    // Modifier to restrict function access to only the admin
    modifier onlyAdmin() {
        require(isAnAdmin[msg.sender], "Only admin can perform this action.");
        _;
    }

     // Function to create a new election with a specified ID
    function createElection(uint electionId) public onlyAdmin {
        require(electionId == nextElectionId, "Election ID must be sequential.");
        require(!elections[electionId].isActive, "Election already exists.");
        elections[electionId].isActive = false;
        nextElectionId++;
    }

    function addCandidate(uint electionId, string memory firstName, string memory lastName, string memory candidateID, string memory politicalParty) public onlyAdmin {
        require(!elections[electionId].isActive, "Cannot add candidates to active elections.");
        uint id = uint(keccak256(abi.encodePacked(candidateID))); // Create a unique ID for each candidate
        elections[electionId].candidates[id] = Candidate(id, firstName, lastName, candidateID, politicalParty, 0);
        elections[electionId].candidateIds.push(id);
    }

    // Function to start an election
    function startElection(uint electionId) public onlyAdmin {
        require(!elections[electionId].isActive, "Election already active.");
        elections[electionId].isActive = true;
    }
    // Function to end an election
    function endElection(uint electionId) public onlyAdmin {
        require(elections[electionId].isActive, "Election is not active or does not exist.");
        elections[electionId].isActive = false;
    }

    // Voting function using last name and secret ID for verification
    function vote(uint electionId, uint candidateId, string memory lastName, uint secretID) public {
        require(elections[electionId].isActive, "Election is not active.");
        require(keccak256(abi.encodePacked(lastName)) == keccak256(abi.encodePacked("Akinlua")), "Invalid last name."); // Using pre saved data for login as I do not have access to database system
        require(secretID == 9068340768, "Invalid secret ID.");
        require(!hasVoted[msg.sender][electionId], "User has already voted in this election.");

        Candidate storage candidate = elections[electionId].candidates[candidateId];
        candidate.voteCount++; // Increment the vote count
        hasVoted[msg.sender][electionId] = true;
    }

    // Function to get the list of candidates for a given election, including their IDs
    function getCandidates(uint electionId) public view returns (string[] memory candidateIDs, string[] memory candidateNames) {
        require(electionId < nextElectionId, "Election does not exist.");
        Election storage election = elections[electionId];
        candidateIDs = new string[](election.candidateIds.length);
        candidateNames = new string[](election.candidateIds.length);

        for (uint i = 0; i < election.candidateIds.length; i++) {
            uint candidateId = election.candidateIds[i];
            Candidate storage candidate = election.candidates[candidateId];
            candidateIDs[i] = candidate.candidateID;
            candidateNames[i] = string(abi.encodePacked(candidate.firstName, " ", candidate.lastName));
        }
        return (candidateIDs, candidateNames);
}

    // Voting function to get election results
    function getElectionResults(uint electionId) public view returns (string[] memory candidateNames, uint[] memory voteCounts) {
        require(electionId < nextElectionId, "Election does not exist.");
        uint[] memory counts = new uint[](elections[electionId].candidateIds.length);
        string[] memory names = new string[](elections[electionId].candidateIds.length);

        for (uint i = 0; i < elections[electionId].candidateIds.length; i++) {
            uint candidateId = elections[electionId].candidateIds[i];
            Candidate storage candidate = elections[electionId].candidates[candidateId];
            counts[i] = candidate.voteCount;
            names[i] = string(abi.encodePacked(candidate.firstName, " ", candidate.lastName));
        }
        return (names, counts); // return the names and vote counts of candidates at the end
    }
}