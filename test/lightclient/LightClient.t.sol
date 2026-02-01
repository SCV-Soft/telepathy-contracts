pragma solidity 0.8.16;

import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

import {SSZ} from "src/libraries/SimpleSerialize.sol";
import {
    LightClient,
    LightClientStep,
    LightClientRotate,
    LightClientOptimizedRotate
} from "src/lightclient/LightClient.sol";
import {LightClientFixture} from "test/lightclient/LightClientFixture.sol";
import {OptLightClientFixture} from "test/lightclient/OptLightClientFixture.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract LightClientTest is Test, LightClientFixture {
    uint32 constant SOURCE_CHAIN_ID = 1;
    uint16 constant FINALITY_THRESHOLD = 350;

    uint256 constant FIXTURE_SLOT_START = 6000991;
    uint256 constant FIXTURE_SLOT_END = 6001088;

    uint256 constant OPT_FIXTURE_SLOT_START = 6440799;
    uint256 constant OPT_FIXTURE_SLOT_END = 6443999;

    Fixture[] fixtures;
    OptLightClientFixture.OptFixture[] optFixtures;

    function setUp() public {
        string memory root = vm.projectRoot();
        for (uint256 i = FIXTURE_SLOT_START; i <= FIXTURE_SLOT_END; i++) {
            uint256 slot = i;

            string memory filename = string.concat("slot", Strings.toString(slot));
            string memory path =
                string.concat(root, "/test/lightclient/fixtures/", filename, ".json");
            try vm.readFile(path) returns (string memory file) {
                try this.parseFixtureFromJson(file) returns (Fixture memory f) {
                    fixtures.push(f);
                } catch {
                    continue;
                }
            } catch {
                continue;
            }
        }

        for (uint256 i = OPT_FIXTURE_SLOT_START; i <= OPT_FIXTURE_SLOT_END; i++) {
            uint256 slot = i;

            string memory filename = string.concat("opt_slot", Strings.toString(slot));
            string memory path =
                string.concat(root, "/test/lightclient/fixtures/", filename, ".json");
            try vm.readFile(path) returns (string memory file) {
                try this.parseOptFixtureFromJson(file) returns (OptLightClientFixture.OptFixture memory f) {
                    optFixtures.push(f);
                } catch {
                    continue;
                }
            } catch {
                continue;
            }
        }

        vm.warp(9999999999999);
    }

    function parseFixtureFromJson(string memory file) external returns (Fixture memory) {
        return _parseFixtureFromJson(file);
    }

    function parseOptFixtureFromJson(string memory file)
        external
        returns (OptLightClientFixture.OptFixture memory)
    {
        return _parseOptFixtureFromJson(file);
    }

    function _parseBytes32(string memory json, string memory key) internal pure returns (bytes32) {
        return abi.decode(vm.parseJson(json, key), (bytes32));
    }

    function _parseFixtureFromJson(string memory file) internal returns (Fixture memory) {
        Initial memory initial = Initial({
            genesisTime: bytes(vm.parseJsonString(file, ".initial.genesisTime")),
            genesisValidatorsRoot: _parseBytes32(file, ".initial.genesisValidatorsRoot"),
            secondsPerSlot: vm.parseJsonUint(file, ".initial.secondsPerSlot"),
            slotsPerPeriod: vm.parseJsonUint(file, ".initial.slotsPerPeriod"),
            syncCommitteePeriod: vm.parseJsonUint(file, ".initial.syncCommitteePeriod"),
            syncCommitteePoseidon: vm.parseJsonString(file, ".initial.syncCommitteePoseidon")
        });

        string[][] memory stepB = new string[][](2);
        stepB[0] = vm.parseJsonStringArray(file, ".step.b[0]");
        stepB[1] = vm.parseJsonStringArray(file, ".step.b[1]");
        Step memory step = Step({
            a: vm.parseJsonStringArray(file, ".step.a"),
            attestedSlot: vm.parseJsonUint(file, ".step.attestedSlot"),
            b: stepB,
            c: vm.parseJsonStringArray(file, ".step.c"),
            executionStateRoot: _parseBytes32(file, ".step.executionStateRoot"),
            finalizedHeaderRoot: _parseBytes32(file, ".step.finalizedHeaderRoot"),
            finalizedSlot: vm.parseJsonUint(file, ".step.finalizedSlot"),
            inputs: vm.parseJsonStringArray(file, ".step.inputs"),
            participation: vm.parseJsonString(file, ".step.participation")
        });

        string[][] memory rotateB = new string[][](2);
        rotateB[0] = vm.parseJsonStringArray(file, ".rotate.b[0]");
        rotateB[1] = vm.parseJsonStringArray(file, ".rotate.b[1]");
        Rotate memory rotate = Rotate({
            a: vm.parseJsonStringArray(file, ".rotate.a"),
            b: rotateB,
            c: vm.parseJsonStringArray(file, ".rotate.c"),
            syncCommitteePoseidon: vm.parseJsonString(file, ".rotate.syncCommitteePoseidon"),
            syncCommitteeSSZ: _parseBytes32(file, ".rotate.syncCommitteeSSZ")
        });

        return Fixture({initial: initial, rotate: rotate, step: step});
    }

    function _parseOptFixtureFromJson(string memory file)
        internal
        returns (OptLightClientFixture.OptFixture memory)
    {
        OptLightClientFixture.Initial memory initial = OptLightClientFixture.Initial({
            genesisTime: bytes(vm.parseJsonString(file, ".initial.genesisTime")),
            genesisValidatorsRoot: _parseBytes32(file, ".initial.genesisValidatorsRoot"),
            secondsPerSlot: vm.parseJsonUint(file, ".initial.secondsPerSlot"),
            slotsPerPeriod: vm.parseJsonUint(file, ".initial.slotsPerPeriod"),
            syncCommitteePeriod: vm.parseJsonUint(file, ".initial.syncCommitteePeriod"),
            syncCommitteePoseidon: vm.parseJsonString(file, ".initial.syncCommitteePoseidon")
        });

        string[][] memory stepB = new string[][](2);
        stepB[0] = vm.parseJsonStringArray(file, ".step.b[0]");
        stepB[1] = vm.parseJsonStringArray(file, ".step.b[1]");
        OptLightClientFixture.Step memory step = OptLightClientFixture.Step({
            a: vm.parseJsonStringArray(file, ".step.a"),
            attestedSlot: vm.parseJsonUint(file, ".step.attestedSlot"),
            b: stepB,
            c: vm.parseJsonStringArray(file, ".step.c"),
            executionStateRoot: _parseBytes32(file, ".step.executionStateRoot"),
            finalizedHeaderRoot: _parseBytes32(file, ".step.finalizedHeaderRoot"),
            finalizedSlot: vm.parseJsonUint(file, ".step.finalizedSlot"),
            inputs: vm.parseJsonStringArray(file, ".step.inputs"),
            participation: vm.parseJsonString(file, ".step.participation")
        });

        string[][] memory rotateB = new string[][](2);
        rotateB[0] = vm.parseJsonStringArray(file, ".rotate.b[0]");
        rotateB[1] = vm.parseJsonStringArray(file, ".rotate.b[1]");
        OptLightClientFixture.Rotate memory rotate = OptLightClientFixture.Rotate({
            a: vm.parseJsonStringArray(file, ".rotate.a"),
            b: rotateB,
            c: vm.parseJsonStringArray(file, ".rotate.c"),
            syncCommitteePoseidon: vm.parseJsonString(file, ".rotate.syncCommitteePoseidon"),
            syncCommitteeSSZ: _parseBytes32(file, ".rotate.syncCommitteeSSZ")
        });

        string[][] memory optimizedRotateB = new string[][](2);
        optimizedRotateB[0] = vm.parseJsonStringArray(file, ".optimizedRotate.b[0]");
        optimizedRotateB[1] = vm.parseJsonStringArray(file, ".optimizedRotate.b[1]");
        OptLightClientFixture.OptimizedRotate memory optimizedRotate = OptLightClientFixture
            .OptimizedRotate({
            a: vm.parseJsonStringArray(file, ".optimizedRotate.a"),
            b: optimizedRotateB,
            c: vm.parseJsonStringArray(file, ".optimizedRotate.c"),
            publicInputsRoot: vm.parseJsonString(file, ".optimizedRotate.publicInputsRoot"),
            syncCommitteePoseidon: vm.parseJsonString(file, ".optimizedRotate.syncCommitteePoseidon"),
            syncCommitteeSSZ: _parseBytes32(file, ".optimizedRotate.syncCommitteeSSZ")
        });

        return OptLightClientFixture.OptFixture({
            initial: initial,
            optimizedRotate: optimizedRotate,
            rotate: rotate,
            step: step
        });
    }

    function test_SetUp() public view {
        require(fixtures.length > 0, "No fixtures loaded - JSON parsing may have failed");
    }

    modifier requireFixtures() {
        require(fixtures.length > 0, "No fixtures loaded");
        _;
    }

    modifier requireFixturesAtLeast(uint256 n) {
        require(fixtures.length >= n, "Not enough fixtures loaded");
        _;
    }

    modifier requireOptFixtures() {
        require(optFixtures.length > 0, "No opt fixtures loaded");
        _;
    }

    function test_Step() public {
        for (uint256 i = 0; i < fixtures.length; i++) {
            Fixture memory fixture = fixtures[i];

            LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
            LightClientStep memory step = convertToLightClientStep(fixture.step);

            lc.step(step);
        }
    }

    function test_StepTimestamp_WhenDuplicateUpdate() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        uint256 currentTimestamp = block.timestamp;
        lc.step(step);
        assertEq(lc.timestamps(step.finalizedSlot), currentTimestamp);

        vm.warp(12345678900);
        lc.step(step);
        assertEq(lc.timestamps(step.finalizedSlot), currentTimestamp);
    }

    function test_Rotate() public {
        for (uint256 i = 0; i < fixtures.length; i++) {
            Fixture memory fixture = fixtures[i];

            LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
            LightClientRotate memory rotate =
                convertToLightClientRotate(fixture.step, fixture.rotate);

            lc.rotate(rotate);
        }
    }

    function test_RotatePublicInputsHash() public requireFixturesAtLeast(3) {
        Fixture memory fixture = fixtures[2];

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientRotate memory rotate = convertToLightClientRotate(fixture.step, fixture.rotate);

        console.log("syncCommitteeSSZ (Bytes32)");
        console.logBytes32(SSZ.toLittleEndian(uint256(rotate.syncCommitteeSSZ)));
        console.log("finalizedHeaderRoot (Bytes32)");
        console.logBytes32(SSZ.toLittleEndian(uint256(rotate.step.finalizedHeaderRoot)));
        console.log("syncCommitteePoseidon (uint256)");
        console.logUint(uint256(SSZ.toLittleEndian(uint256(rotate.syncCommitteePoseidon))));

        lc.rotate(rotate);

        bytes32 h = sha256(
            bytes.concat(
                SSZ.toLittleEndian(uint256(rotate.step.finalizedHeaderRoot)),
                SSZ.toLittleEndian(uint256(rotate.syncCommitteeSSZ)),
                rotate.syncCommitteePoseidon
            )
        );

        uint256 t = uint256(SSZ.toLittleEndian(uint256(h)));
        t = t & ((uint256(1) << 253) - 1);
        console.log("Output Hash (BigInt)");
        console.logUint(uint256(t));
        console.log("Output Hash (bytes32)");
        console.logBytes32(SSZ.toLittleEndian(uint256(t)));
    }

    function test_OptimizedRotate() public {
        OptLightClientFixture newContract = new OptLightClientFixture();
        for (uint256 i = 0; i < optFixtures.length; i++) {
            OptLightClientFixture.OptFixture memory optFixture = optFixtures[i];

            LightClient lc = newContract.newOptLightClient(
                optFixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD
            );
            LightClientOptimizedRotate memory optRotate = newContract
                .convertToLightClientOptimizedRotate(optFixture.step, optFixture.optimizedRotate);

            lc.optimizedRotate(optRotate);
        }
    }

    function test_RotateGasCost() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);

        LightClientRotate memory rotate = convertToLightClientRotate(fixture.step, fixture.rotate);

        LightClientStep memory step = convertToLightClientStep(fixture.step);

        uint256 gas = gasleft();
        lc.step(step);
        console.log("gas cost for step: %d", gas - gasleft());

        gas = gasleft();
        lc.rotate(rotate);
        console.log("gas cost for rotate: %d", gas - gasleft());
    }

    function test_OptimizedRotateGasCost() public requireOptFixtures {
        OptLightClientFixture.OptFixture memory fixture = optFixtures[0];

        OptLightClientFixture newContract = new OptLightClientFixture();
        LightClientOptimizedRotate memory optRotate =
            newContract.convertToLightClientOptimizedRotate(fixture.step, fixture.optimizedRotate);

        LightClient lc =
            newContract.newOptLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);

        uint256 gas = gasleft();
        lc.optimizedRotate(optRotate);
        console.log("gas cost for optimized rotate: %d", gas - gasleft());
    }

    // Particularly important as an early slot (within in the first 2 epochs of a period) will have
    // the the attested slot and finalized slot land in different Sync Committee periods.
    function test_Rotate_WhenSyncCommitteePeriodEarlySlot() public {
        string memory path = string.concat(
            vm.projectRoot(), "/test/lightclient/fixtures/periodBoundaryEarlySlot.json"
        );
        Fixture memory fixture = _parseFixtureFromJson(vm.readFile(path));

        uint256 attestedSlotPeriod = fixture.step.attestedSlot / fixture.initial.slotsPerPeriod;
        uint256 finalizedSlotPeriod = fixture.step.finalizedSlot / fixture.initial.slotsPerPeriod;

        // ensure that there is a different period between the attested slot and finalized slot
        assertTrue(finalizedSlotPeriod < attestedSlotPeriod);

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientRotate memory rotate = convertToLightClientRotate(fixture.step, fixture.rotate);

        lc.rotate(rotate);

        assertEq(lc.syncCommitteePoseidons(finalizedSlotPeriod), 0);
        assertEq(lc.syncCommitteePoseidons(attestedSlotPeriod), rotate.syncCommitteePoseidon);

        LightClientStep memory step = convertToLightClientStep(fixture.step);

        lc.step(step);
    }

    function test_Rotate_WhenSyncCommitteePeriodLateSlot() public {
        string memory path = string.concat(
            vm.projectRoot(), "/test/lightclient/fixtures/periodBoundaryLateSlot.json"
        );
        Fixture memory fixture = _parseFixtureFromJson(vm.readFile(path));

        uint256 attestedSlotPeriod = fixture.step.attestedSlot / fixture.initial.slotsPerPeriod;
        uint256 finalizedSlotPeriod = fixture.step.finalizedSlot / fixture.initial.slotsPerPeriod;

        // ensure that the attested slot is the last slot of the period
        assertEq((fixture.step.attestedSlot + 1) % fixture.initial.slotsPerPeriod, 0);

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientRotate memory rotate = convertToLightClientRotate(fixture.step, fixture.rotate);

        lc.rotate(rotate);

        assertEq(lc.syncCommitteePoseidons(finalizedSlotPeriod), rotate.syncCommitteePoseidon);
        assertEq(lc.syncCommitteePoseidons(attestedSlotPeriod), rotate.syncCommitteePoseidon);

        LightClientStep memory step = convertToLightClientStep(fixture.step);

        lc.step(step);
    }

    function test_RawStepProof() public {
        for (uint256 i = 0; i < fixtures.length; i++) {
            Fixture memory fixture = fixtures[i];

            LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);

            uint256[2] memory a = [strToUint(fixture.step.a[0]), strToUint(fixture.step.a[1])];
            uint256[2][2] memory b = [
                [strToUint(fixture.step.b[0][1]), strToUint(fixture.step.b[0][0])],
                [strToUint(fixture.step.b[1][1]), strToUint(fixture.step.b[1][0])]
            ];
            uint256[2] memory c = [strToUint(fixture.step.c[0]), strToUint(fixture.step.c[1])];
            uint256[1] memory inputs = [strToUint(fixture.step.inputs[0])];

            assertTrue(lc.verifyProofStep(a, b, c, inputs));
        }
    }

    function test_RawRotateProof() public {
        for (uint256 i = 0; i < fixtures.length; i++) {
            Fixture memory fixture = fixtures[i];

            LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);

            uint256[2] memory a = [strToUint(fixture.rotate.a[0]), strToUint(fixture.rotate.a[1])];
            uint256[2][2] memory b = [
                [strToUint(fixture.rotate.b[0][1]), strToUint(fixture.rotate.b[0][0])],
                [strToUint(fixture.rotate.b[1][1]), strToUint(fixture.rotate.b[1][0])]
            ];
            uint256[2] memory c = [strToUint(fixture.rotate.c[0]), strToUint(fixture.rotate.c[1])];

            LightClientRotate memory rotate =
                convertToLightClientRotate(fixture.step, fixture.rotate);

            uint256[65] memory inputs;
            uint256 syncCommitteeSSZNumeric = uint256(rotate.syncCommitteeSSZ);
            for (uint256 j = 0; j < 32; j++) {
                inputs[32 - 1 - j] = syncCommitteeSSZNumeric % 2 ** 8;
                syncCommitteeSSZNumeric = syncCommitteeSSZNumeric / 2 ** 8;
            }
            uint256 finalizedHeaderRootNumeric = uint256(fixture.step.finalizedHeaderRoot);
            for (uint256 j = 0; j < 32; j++) {
                inputs[64 - j] = finalizedHeaderRootNumeric % 2 ** 8;
                finalizedHeaderRootNumeric = finalizedHeaderRootNumeric / 2 ** 8;
            }
            inputs[32] = uint256(SSZ.toLittleEndian(uint256(rotate.syncCommitteePoseidon)));

            assertTrue(lc.verifyProofRotate(a, b, c, inputs));
        }
    }

    function test_RevertStep_WhenBadA() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.step.a[0] = "0";

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        vm.expectRevert();
        lc.step(step);
    }

    function test_RevertStep_WhenBadB() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.step.b[0][0] = "0";

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        vm.expectRevert();
        lc.step(step);
    }

    function test_RevertStep_WhenBadC() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.step.c[0] = "0";

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        vm.expectRevert();
        lc.step(step);
    }

    function test_RevertStep_WhenBadAttestedSlot() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.step.attestedSlot = 0;

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        vm.expectRevert();
        lc.step(step);
    }

    function test_RevertStep_WhenBadFinalizedSlot() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.step.finalizedSlot = 0;

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        vm.expectRevert();
        lc.step(step);
    }

    function test_RevertStep_WhenBadParticipation() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.step.participation = Strings.toString(FINALITY_THRESHOLD - 1);

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        vm.expectRevert();
        lc.step(step);
    }

    function test_RevertStep_WhenBadFinalizedHeaderRoot() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.step.finalizedHeaderRoot = "0";

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        vm.expectRevert();
        lc.step(step);
    }

    function test_RevertStep_WhenBadExecutionStateRoot() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.step.executionStateRoot = "0";

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        vm.expectRevert();
        lc.step(step);
    }

    function test_RevertStep_WhenSlotBelowPeriodBoundary() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.initial.syncCommitteePeriod++;

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        vm.expectRevert();
        lc.step(step);
    }

    function test_RevertStep_WhenSlotAbovePeriodBoundary() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.initial.syncCommitteePeriod--;

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory step = convertToLightClientStep(fixture.step);

        vm.expectRevert();
        lc.step(step);
    }

    function test_RevertStep_WhenFinalizedSlotIsOlder() public requireFixturesAtLeast(3) {
        Fixture memory newerFixture = fixtures[2];
        Fixture memory olderFixture = fixtures[1];

        LightClient lc = newLightClient(newerFixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientStep memory newerStep = convertToLightClientStep(newerFixture.step);
        LightClientStep memory olderStep = convertToLightClientStep(olderFixture.step);

        lc.step(newerStep);

        vm.expectRevert("Update slot less than current head");
        lc.step(olderStep);
    }

    function test_RevertRotate_WhenBadA() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.rotate.a[0] = "0";

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientRotate memory rotate = convertToLightClientRotate(fixture.step, fixture.rotate);

        vm.expectRevert();
        lc.rotate(rotate);
    }

    function test_RevertRotate_WhenBadB() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.rotate.b[0][0] = "0";

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientRotate memory rotate = convertToLightClientRotate(fixture.step, fixture.rotate);

        vm.expectRevert();
        lc.rotate(rotate);
    }

    function test_RevertRotate_WhenBadC() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.rotate.c[0] = "0";

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientRotate memory rotate = convertToLightClientRotate(fixture.step, fixture.rotate);

        vm.expectRevert();
        lc.rotate(rotate);
    }

    function test_RevertRotate_WhenBadSyncCommitteeSSZ() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.rotate.syncCommitteeSSZ = 0;

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientRotate memory rotate = convertToLightClientRotate(fixture.step, fixture.rotate);

        vm.expectRevert();
        lc.rotate(rotate);
    }

    function test_RevertRotate_WhenBadSyncCommitteePoseidon() public requireFixtures {
        Fixture memory fixture = fixtures[0];

        fixture.rotate.syncCommitteePoseidon = "0";

        LightClient lc = newLightClient(fixture.initial, SOURCE_CHAIN_ID, FINALITY_THRESHOLD);
        LightClientRotate memory rotate = convertToLightClientRotate(fixture.step, fixture.rotate);

        vm.expectRevert();
        lc.rotate(rotate);
    }
}
