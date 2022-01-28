// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./Project.sol";
import "./Paper.sol";

import "hardhat/console.sol";

contract CrowdFunding {
    using SafeMathUpgradeable for uint256;

    // List of existing projects
    Project[] public projects;

    uint256 public projectAmount;

    // List of existing paper
    Paper[] public papers;

    uint256 public paperAmount;

    /** @dev Function to start a new project.
      * @param _title Title of the project to be created
      * @param _description Brief description about the project
      * @param _timeToSubmitWork Project deadline in seconds
      */
    function startProject(
        string memory _creatorName,
        string memory _title,
        string memory _description,
        uint _timeToSubmitWork,
        uint256 _price,
        uint256 _limit,
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) external {
        uint256 raiseUntil = block.timestamp.add(_timeToSubmitWork);

        projectAmount = projectAmount.add(1);

        Project newProject = new Project{salt: keccak256(abi.encode(msg.sender, projectAmount))}();

        Project(newProject).init(
            _creatorName,
            msg.sender,
            _title,
            _description,
            _timeToSubmitWork,
            _price,
            _limit,
            _name,
            _symbol,
            _baseTokenURI
        );
        projects.push(newProject);

        emit ProjectStarted(
            address(newProject),
            msg.sender,
            _creatorName,
            _title,
            _description,
            _timeToSubmitWork,
            _price,
            _limit,
            _name,
            _symbol,
            _baseTokenURI
        );
    }

    /** @dev Function to start a new project.
      * @param _title Title of the project to be created
      * @param _description Brief description about the project
      */
    function startPaperMining(
        string memory _creatorName,
        string memory _title,
        string memory _description,
        uint256 _price,
        uint256 _limit,
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        string memory _paperURL
    ) external {
        paperAmount = paperAmount.add(1);

        Paper newPaper = new Paper{salt: keccak256(abi.encode(msg.sender, paperAmount))}();

        Paper(newPaper).init(
            _creatorName,
            msg.sender,
            _title,
            _description,
            _price,
            _limit,
            _name,
            _symbol,
            _baseTokenURI,
            _paperURL
        );
        papers.push(newPaper);

        emit PaperStarted(
            address(newPaper),
            msg.sender,
            _creatorName,
            _title,
            _description,
            _price,
            _limit,
            _name,
            _symbol,
            _baseTokenURI,
            _paperURL
        );
    }

    function getCurrentTime() external view returns(uint256) {
        return block.timestamp;
    }

    /** @dev Function to get all projects' contract addresses.
      * @return A list of all projects' contract addreses
      */
    function returnAllProjects() external view returns(Project[] memory){
        return projects;
    }

    /** @dev Function to get all papers' contract addresses.
      * @return A list of all papers' contract addreses
      */
    function returnAllPapers() external view returns(Paper[] memory){
        return papers;
    }

    // Event that will be emitted whenever a new project is started
    event ProjectStarted(
        address contractAddress,
        address creatorAddress,
        string creatorName,
        string title,
        string description,
        uint256 deadline,
        uint256 price,
        uint256 limit,
        string name,
        string symbol,
        string baseTokenURI

    );

    // Event that will be emitted whenever a new paper is started
    event PaperStarted(
        address contractAddress,
        address creatorAddress,
        string creatorName,
        string title,
        string description,
        uint256 price,
        uint256 limit,
        string name,
        string symbol,
        string baseTokenURI,
        string paperURL
    );

}


