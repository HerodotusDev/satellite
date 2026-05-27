// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {Test, Vm} from "forge-std/Test.sol";
import {Satellite} from "../src/Satellite.sol";
import {SatelliteMaintenanceModule} from "../src/modules/SatelliteMaintenanceModule.sol";
import {OwnershipModule} from "../src/modules/OwnershipModule.sol";
import {CairoFactRegistryModule} from "../src/modules/CairoFactRegistryModule.sol";
import {SP1FactRegistryModule} from "../src/modules/SP1FactRegistryModule.sol";
import {ISP1Verifier} from "../src/interfaces/external/ISP1Verifier.sol";
import {ISatellite} from "../src/interfaces/ISatellite.sol";
import {ISP1FactRegistryModule} from "../src/interfaces/modules/ISP1FactRegistryModule.sol";
import {ILibSatellite} from "../src/interfaces/ILibSatellite.sol";
import {MockFactsRegistry} from "../src/mocks/MockFactsRegistry.sol";

contract SP1FactRegistryModuleTest is Test {
    ISatellite internal satellite;
    address internal satelliteAddr;

    address internal constant VERIFIER = address(0xBEEF);
    bytes32 internal constant VKEY = bytes32(uint256(0x1234));
    bytes32 internal constant FACT = bytes32(uint256(0xCAFE));

    address internal owner;
    address internal admin = address(0xAD);
    address internal alice = address(0xA11CE);

    function setUp() public {
        owner = address(this);

        // Deploy Diamond
        SatelliteMaintenanceModule maintenanceModule = new SatelliteMaintenanceModule();
        Satellite diamond = new Satellite(address(maintenanceModule));
        satelliteAddr = address(diamond);
        satellite = ISatellite(satelliteAddr);

        // Deploy modules
        OwnershipModule ownershipModule = new OwnershipModule();
        CairoFactRegistryModule cairoModule = new CairoFactRegistryModule();
        SP1FactRegistryModule sp1Module = new SP1FactRegistryModule();

        // Prepare Diamond cut
        ILibSatellite.ModuleMaintenance[] memory cuts = new ILibSatellite.ModuleMaintenance[](3);

        // OwnershipModule selectors
        bytes4[] memory ownershipSelectors = new bytes4[](4);
        ownershipSelectors[0] = OwnershipModule.transferOwnership.selector;
        ownershipSelectors[1] = OwnershipModule.owner.selector;
        ownershipSelectors[2] = OwnershipModule.isAdmin.selector;
        ownershipSelectors[3] = OwnershipModule.manageAdmins.selector;
        cuts[0] = ILibSatellite.ModuleMaintenance({
            moduleAddress: address(ownershipModule),
            action: ILibSatellite.ModuleMaintenanceAction.Add,
            functionSelectors: ownershipSelectors
        });

        // CairoFactRegistryModule selectors
        bytes4[] memory cairoSelectors = new bytes4[](14);
        cairoSelectors[0] = CairoFactRegistryModule.isCairoFactValid.selector;
        cairoSelectors[1] = CairoFactRegistryModule.isCairoVerifiedFactValid.selector;
        cairoSelectors[2] = CairoFactRegistryModule.isCairoVerifiedFactStored.selector;
        cairoSelectors[3] = CairoFactRegistryModule.getCairoVerifiedFactRegistryContract.selector;
        cairoSelectors[4] = CairoFactRegistryModule.setCairoVerifiedFactRegistryContract.selector;
        cairoSelectors[5] = CairoFactRegistryModule.storeCairoVerifiedFact.selector;
        cairoSelectors[6] = CairoFactRegistryModule.isCairoMockedFactValid.selector;
        cairoSelectors[7] = CairoFactRegistryModule.setCairoMockedFact.selector;
        cairoSelectors[8] = CairoFactRegistryModule.getCairoMockedFactRegistryFallbackContract.selector;
        cairoSelectors[9] = CairoFactRegistryModule.setCairoMockedFactRegistryFallbackContract.selector;
        cairoSelectors[10] = CairoFactRegistryModule.isCairoFactValidForInternal.selector;
        cairoSelectors[11] = CairoFactRegistryModule.isMockedForInternal.selector;
        cairoSelectors[12] = CairoFactRegistryModule.setIsMockedForInternal.selector;
        cairoSelectors[13] = CairoFactRegistryModule._receiveCairoFactHash.selector;
        cuts[1] = ILibSatellite.ModuleMaintenance({moduleAddress: address(cairoModule), action: ILibSatellite.ModuleMaintenanceAction.Add, functionSelectors: cairoSelectors});

        // SP1FactRegistryModule selectors
        bytes4[] memory sp1Selectors = new bytes4[](6);
        sp1Selectors[0] = SP1FactRegistryModule.verifyAndRegisterSP1Fact.selector;
        sp1Selectors[1] = SP1FactRegistryModule.isFactValid.selector;
        sp1Selectors[2] = SP1FactRegistryModule.setProgramVKey.selector;
        sp1Selectors[3] = SP1FactRegistryModule.setSP1Verifier.selector;
        sp1Selectors[4] = SP1FactRegistryModule.getSP1Verifier.selector;
        sp1Selectors[5] = SP1FactRegistryModule.getProgramVKey.selector;
        cuts[2] = ILibSatellite.ModuleMaintenance({moduleAddress: address(sp1Module), action: ILibSatellite.ModuleMaintenanceAction.Add, functionSelectors: sp1Selectors});

        // Execute Diamond cut
        satellite.satelliteMaintenance(cuts, address(0), "");

        // Set up mock external fact registry (needed for isCairoVerifiedFactValid)
        MockFactsRegistry mockFactsRegistry = new MockFactsRegistry();
        satellite.setCairoVerifiedFactRegistryContract(address(mockFactsRegistry));

        // Set up admin
        address[] memory admins = new address[](1);
        admins[0] = admin;
        satellite.manageAdmins(admins, true);

        // Configure SP1 module
        satellite.setSP1Verifier(VERIFIER);
        vm.prank(admin);
        satellite.setProgramVKey(VKEY);
    }

    // ========================= Helpers ========================= //

    function _publicValues(bytes32 factHash) internal pure returns (bytes memory) {
        return abi.encode(factHash);
    }

    function _mockVerifierOk(bytes memory publicValues, bytes memory proofBytes) internal {
        vm.mockCall(VERIFIER, abi.encodeWithSelector(ISP1Verifier.verifyProof.selector, VKEY, publicValues, proofBytes), "");
    }

    // ========================= Happy Path ========================= //

    function test_verifyAndRegister_happyPath() public {
        bytes memory publicValues = _publicValues(FACT);
        bytes memory proofBytes = hex"deadbeef";
        _mockVerifierOk(publicValues, proofBytes);

        vm.expectEmit(true, true, true, true, satelliteAddr);
        emit ISP1FactRegistryModule.SP1FactRegistered(FACT, alice);

        vm.prank(alice);
        satellite.verifyAndRegisterSP1Fact(publicValues, proofBytes);

        assertTrue(satellite.isFactValid(FACT));
        assertTrue(satellite.isCairoVerifiedFactStored(FACT));
        assertTrue(satellite.isCairoFactValid(FACT, false));
    }

    // ========================= Invalid Proof ========================= //

    function test_verifyAndRegister_invalidProof_reverts() public {
        bytes memory publicValues = _publicValues(FACT);
        bytes memory proofBytes = hex"deadbeef";
        vm.mockCallRevert(VERIFIER, abi.encodeWithSelector(ISP1Verifier.verifyProof.selector, VKEY, publicValues, proofBytes), bytes("InvalidProof"));

        vm.expectRevert(bytes("InvalidProof"));
        satellite.verifyAndRegisterSP1Fact(publicValues, proofBytes);

        assertFalse(satellite.isFactValid(FACT));
    }

    // ========================= Idempotency ========================= //

    function test_verifyAndRegister_idempotent() public {
        bytes memory publicValues = _publicValues(FACT);
        bytes memory proofBytes = hex"deadbeef";
        _mockVerifierOk(publicValues, proofBytes);

        satellite.verifyAndRegisterSP1Fact(publicValues, proofBytes);
        assertTrue(satellite.isFactValid(FACT));

        vm.recordLogs();
        satellite.verifyAndRegisterSP1Fact(publicValues, proofBytes);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        bytes32 sig = keccak256("SP1FactRegistered(bytes32,address)");
        for (uint256 i = 0; i < logs.length; i++) {
            assertFalse(logs[i].emitter == satelliteAddr && logs[i].topics.length > 0 && logs[i].topics[0] == sig, "SP1FactRegistered emitted on idempotent call");
        }
        assertTrue(satellite.isFactValid(FACT));
    }

    // ========================= VKey Management ========================= //

    function test_setProgramVKey_byAdmin() public {
        bytes32 newVKey = bytes32(uint256(0x9999));

        vm.expectEmit(true, true, true, true, satelliteAddr);
        emit ISP1FactRegistryModule.VKeyUpdated(VKEY, newVKey);

        vm.prank(admin);
        satellite.setProgramVKey(newVKey);

        assertEq(satellite.getProgramVKey(), newVKey);
    }

    function test_setProgramVKey_byNonAdmin_reverts() public {
        vm.prank(alice);
        vm.expectRevert("You are not an admin");
        satellite.setProgramVKey(bytes32(uint256(0x9999)));
    }

    function test_setProgramVKey_byOwner_reverts() public {
        vm.expectRevert("You are not an admin");
        satellite.setProgramVKey(bytes32(uint256(0x9999)));
    }

    // ========================= Verifier Management ========================= //

    function test_setSP1Verifier_byOwner() public {
        address newVerifier = address(0xDEAD);

        vm.expectEmit(true, true, true, true, satelliteAddr);
        emit ISP1FactRegistryModule.SP1VerifierUpdated(VERIFIER, newVerifier);

        satellite.setSP1Verifier(newVerifier);

        assertEq(satellite.getSP1Verifier(), newVerifier);
    }

    function test_setSP1Verifier_byNonOwner_reverts() public {
        vm.prank(alice);
        vm.expectRevert();
        satellite.setSP1Verifier(address(0xDEAD));
    }

    function test_setSP1Verifier_zeroAddress_reverts() public {
        vm.expectRevert("SP1: zero address");
        satellite.setSP1Verifier(address(0));
    }

    // ========================= VKey Rotation + Verification ========================= //

    function test_verifyAfterVKeyRotation() public {
        bytes32 newVKey = bytes32(uint256(0x5678));
        vm.prank(admin);
        satellite.setProgramVKey(newVKey);

        bytes memory publicValues = _publicValues(FACT);
        bytes memory proofBytes = hex"deadbeef";

        // Mock with NEW vkey
        vm.mockCall(VERIFIER, abi.encodeWithSelector(ISP1Verifier.verifyProof.selector, newVKey, publicValues, proofBytes), "");

        vm.prank(alice);
        satellite.verifyAndRegisterSP1Fact(publicValues, proofBytes);
        assertTrue(satellite.isFactValid(FACT));
    }

    // ========================= Getters ========================= //

    function test_getters_returnCorrectValues() public view {
        assertEq(satellite.getSP1Verifier(), VERIFIER);
        assertEq(satellite.getProgramVKey(), VKEY);
    }

    function test_isFactValid_unregistered_returnsFalse() public view {
        assertFalse(satellite.isFactValid(bytes32(uint256(0xDEAD))));
    }

    // ========================= Verifier Not Set ========================= //

    function test_verifyAndRegister_verifierNotSet_reverts() public {
        // Deploy a fresh diamond without setting verifier
        SatelliteMaintenanceModule maintenanceModule = new SatelliteMaintenanceModule();
        Satellite diamond = new Satellite(address(maintenanceModule));
        ISatellite freshSatellite = ISatellite(address(diamond));

        SP1FactRegistryModule sp1Module = new SP1FactRegistryModule();
        CairoFactRegistryModule cairoModule = new CairoFactRegistryModule();

        ILibSatellite.ModuleMaintenance[] memory cuts = new ILibSatellite.ModuleMaintenance[](2);

        bytes4[] memory cairoSelectors = new bytes4[](1);
        cairoSelectors[0] = CairoFactRegistryModule._receiveCairoFactHash.selector;
        cuts[0] = ILibSatellite.ModuleMaintenance({moduleAddress: address(cairoModule), action: ILibSatellite.ModuleMaintenanceAction.Add, functionSelectors: cairoSelectors});

        bytes4[] memory sp1Selectors = new bytes4[](1);
        sp1Selectors[0] = SP1FactRegistryModule.verifyAndRegisterSP1Fact.selector;
        cuts[1] = ILibSatellite.ModuleMaintenance({moduleAddress: address(sp1Module), action: ILibSatellite.ModuleMaintenanceAction.Add, functionSelectors: sp1Selectors});

        freshSatellite.satelliteMaintenance(cuts, address(0), "");

        vm.expectRevert("SP1: verifier not set");
        freshSatellite.verifyAndRegisterSP1Fact(_publicValues(FACT), hex"deadbeef");
    }

    // ========================= Cross-module Integration ========================= //

    function test_sp1FactReadableViaCairoFactValid() public {
        bytes memory publicValues = _publicValues(FACT);
        bytes memory proofBytes = hex"deadbeef";
        _mockVerifierOk(publicValues, proofBytes);

        assertFalse(satellite.isCairoFactValid(FACT, false));

        satellite.verifyAndRegisterSP1Fact(publicValues, proofBytes);

        assertTrue(satellite.isCairoFactValid(FACT, false));
        assertTrue(satellite.isCairoVerifiedFactStored(FACT));
        assertTrue(satellite.isCairoVerifiedFactValid(FACT));
    }
}
