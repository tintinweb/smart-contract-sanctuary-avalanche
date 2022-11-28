# @vesion ^0.3.6

@external
@payable
def __init__():
    pass

@external
@view
def multicall(
    target: DynArray[address, max_value(uint8)],
    data: DynArray[Bytes[max_value(uint8)], max_value(uint8)],
) -> DynArray[Bytes[max_value(uint8)], max_value(uint8)]:
    assert len(target) == len(data), "len(target) != len(data)"
    results: DynArray[Bytes[max_value(uint8)], max_value(uint8)] = []
    idx: uint256 = 0
    for i in target:
        res: Bytes[max_value(uint8)] = raw_call(
            target[idx],
            data[idx],
            max_outsize=max_value(uint8),
            is_static_call=True,
        )
        results.append(res)
        idx += 1
    return results