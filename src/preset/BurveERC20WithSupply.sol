// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// diy
import "./BurveERC20Mixed.sol";

contract BurveERC20WithSupply is BurveERC20Mixed {
    uint256 private _circulatingSupply;

    function initialize(
        address bondingCurveAddress,
        string memory name,
        string memory symbol,
        string memory metadata,
        address projectAdmin,
        address projectTreasury,
        uint256 projectMintTax,
        uint256 projectBurnTax,
        address raisingTokenAddr,
        bytes memory parameters,
        address factory
    ) public virtual override initializer {
        (uint256 totalSupply, bytes memory _parameters) = abi.decode(parameters, (uint256, bytes));
        require(bytes(name).length > 0 && bytes(symbol).length > 0, "symbol or name can not be empty");
        __ERC20_init(name, symbol);
        _changeCoinMaker(bondingCurveAddress);
        _initProject(projectAdmin, projectTreasury);
        _initFactory(factory);
        _setMetadata(metadata);
        _bondingCurveParameters = _parameters;
        _raisingToken = raisingTokenAddr;
        _initTaxRate(projectMintTax, projectBurnTax);

        _setupRole(FACTORY_ROLE, factory);

        _setupRole(PROJECT_ADMIN_ROLE, projectAdmin);
        _mint(address(this), totalSupply);
    }

    function _mintInternal(address account, uint256 amount) internal virtual override {
        _circulatingSupply += amount;
        _transfer(address(this), account, amount);
    }

    function _burnInternal(address account, uint256 amount) internal virtual override {
        _circulatingSupply -= amount;
        _transfer(account, address(this), amount);
    }

    function circulatingSupply() public view virtual override returns (uint256) {
        return _circulatingSupply;
    }
}
