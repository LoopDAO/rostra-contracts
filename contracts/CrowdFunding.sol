// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./Project.sol";
import "hardhat/console.sol";


contract CrowdFunding {
    using SafeMathUpgradeable for uint256;

    // List of existing projects
    Project[] private projects;

    uint256 public projectAmount;

    // Event that will be emitted whenever a new project is started
    event ProjectStarted(
        address contractAddress,
        address projectStarter,
        string creatorName,
        string projectTitle,
        string projectDesc,
        uint256 deadline,
        uint256 _price,
        uint256 _limit,
        string _name,
        string _symbol,
        string _baseTokenURI

    );

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

        console.log(address(newProject));

        Project(newProject).initialize(
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
      * @param title Title of the project to be created
      * @param description Brief description about the project
      */
    function startPaperMining(
        string memory creatorName,
        string memory title,
        string memory description,
        uint256 _price,
        uint256 _limit,
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 reserved
    ) external {

        // uint raiseUntil = block.timestamp.add(durationInSeconds);
        // Project newProject = new Project(
        //     creatorName,
        //     payable(msg.sender),
        //     title,
        //     description,
        //     raiseUntil,
        //     _price,
        //     _limit
        // );
        // projects.push(newProject);

        // Project(newProject).initialize(_name, _symbol, _baseTokenURI);

        // emit ProjectStarted(
        //     address(newProject),
        //     msg.sender,
        //     creatorName,
        //     title,
        //     description,
        //     raiseUntil,
        //     _price,
        //     _limit,
        //     _name,
        //     _symbol,
        //     _baseTokenURI
        // );
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

    /** @dev Function to get paper mining's amount.
      * @return Number of paper mining
      */
    function paperMiningAmount() external view returns(uint256){
        return 1;
    }
}


