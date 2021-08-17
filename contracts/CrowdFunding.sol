// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './SafeMath.sol';
import './Project.sol';


contract CrowdFunding {
    using SafeMath for uint256;

    // List of existing projects
    Project[] private projects;

    // Event that will be emitted whenever a new project is started
    event ProjectStarted(
        address contractAddress,
        address projectStarter,
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
      * @param title Title of the project to be created
      * @param description Brief description about the project
      * @param durationInDays Project deadline in days
      */
    function startProject(
        string calldata title,
        string calldata description,
        uint durationInDays,
        uint256 _price,
        uint256 _limit,
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) external {
        uint raiseUntil = block.timestamp.add(durationInDays);
        Project newProject = new Project(
            payable(msg.sender),
            title,
            description,
            raiseUntil,
            _price,
            _limit
        );
        projects.push(newProject);

        Project(newProject).initialize(_name, _symbol, _baseTokenURI);

        emit ProjectStarted(
            address(newProject),
            msg.sender,
            title,
            description,
            raiseUntil,
            _price,
            _limit,
            _name,
            _symbol,
            _baseTokenURI
        );
    }

    /** @dev Function to get all projects' contract addresses.
      * @return A list of all projects' contract addreses
      */
    function returnAllProjects() external view returns(Project[] memory){
        return projects;
    }

    // todo
    function setProjectGracePeriod(address _project, uint256 _gracePeriod) external {
        Project(_project).setGracePeriod(_gracePeriod);
    }

}


