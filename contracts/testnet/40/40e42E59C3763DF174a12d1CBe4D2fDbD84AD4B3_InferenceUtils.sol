// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../structs/InferenceStructs.sol";

// TODO: add to documentation
library InferenceUtils {

    function buildRequest(
        InferenceMetadata memory inferenceMetadata,
        bytes memory data,
        string calldata reqABIFragment,
        InferenceCallback memory inferenceCallback
    ) external pure returns (InferenceRequest memory) {
        return
            InferenceRequest({
                metadata: inferenceMetadata,
                data: data,
                requestABIFragment: reqABIFragment,
                callback: inferenceCallback
            });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct InferenceCallback {
    address callbackContract;
    bytes4 functionSelector;
    string responseABIFragment;
}

struct InferenceMetadata {
    string service_uri;
    string data_layout;
}

struct InferenceRequest {
    InferenceMetadata metadata;
    bytes data;
    string requestABIFragment;
    InferenceCallback callback;
}

struct InferenceResponseData {
    bytes data;
    string jobRunID;
    uint256 statusCode;
}

struct InferenceResponse {
    string peer_id;
    InferenceResponseData data;
}