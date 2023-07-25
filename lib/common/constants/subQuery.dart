// graphql query
const transferQuery = r'''
  query ($account: String, $token: String) {
    transfers(filter: {
      tokenId: { equalTo: $token },
      or: [
        { fromId: { equalTo: $account } },
        { toId: { equalTo: $account } }
      ]
    }, first: 10, orderBy: TIMESTAMP_DESC) {
      nodes {
        id
        from {id}
        to {id}
        token {id}
        amount
        isSuccess
        timestamp
        extrinsic {
          id
        }
      }
    }
  }
''';
const loanQuery = r'''
  query ($account: String) {
    loanActions(filter: {accountId: {equalTo: $account}},
      orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        type
        data
        timestamp
        extrinsic {
          id
          method
          isSuccess
        }
      }
    }
  }
''';
const swapQueryParam = r'$account: String';
const swapQueryFilter = r'''filter: { addressId: { equalTo: $account } }
      first: 20
      orderBy: TIMESTAMP_DESC''';
const swapQuerySchema = '''id
        token0Id
        token1Id
        blockId
        extrinsicId
        timestamp''';
const swapQuery = '''
  query ($swapQueryParam) {
    swaps(
      $swapQueryFilter
    ) {
      nodes {
        $swapQuerySchema
        token0InAmount
        token1OutAmount
      }
    }
    addLiquidities(
      $swapQueryFilter
    ) {
      nodes {
        $swapQuerySchema
        token0Amount
        token1Amount
      }
    }
    addProvisions(
      $swapQueryFilter
    ) {
      nodes {
        $swapQuerySchema
        token0Amount
        token1Amount
      }
    }
    removeLiquidities(
      $swapQueryFilter
    ) {
      nodes {
        $swapQuerySchema
        token0Amount
        token1Amount
        shareAmount
      }
    }
  }
''';

const dexStakeQuery = r'''
  query ($account: String) {
    incentiveActions(filter: {accountId: {equalTo: $account}},
      orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        type
        data
        timestamp
        extrinsic {
          id
          method
          isSuccess
        }
      }
    }
  }
''';
const homaQuery = r'''
  query ($account: String) {
    homaActions(filter: {accountId: {equalTo: $account}},
      orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        type
        data
        timestamp
        extrinsic {
          id
          method
          timestamp
          isSuccess
        }
      }
    }
  }
''';

const queryPoolDetail = r'''
  query ($pool: String) {
    pools(filter: {id: {equalTo: $pool}}) {
      nodes {
        id,
        token0 {id,decimals, name }
        token1 {id,decimals, name }
        token0Amount
        token1Amount
        tradeVolumeUSD
        dayData(orderBy:TIMESTAMP_DESC,first:30) {
          nodes {
            id
            timestamp
            totalTVL
          }
        }
      }
    }
  }
''';

const multiplyQuery = r'''
query ($senderId: String) {
    extrinsics(filter: {
      section :{equalTo :"honzon"},
      or:[{method:{equalTo:"expandPositionCollateral"}}, {method:{equalTo:"shrinkPositionDebit"}}],
      senderId: {equalTo: $senderId}},
      first: 20,orderBy:BLOCK_ID_DESC) {
      nodes {
        id
        method
        section
        updatePositions {
          nodes{
            collateralId
            collateralAdjustment
            debitAdjustment
            timestamp
            extrinsicId
            debitExchangeRate
          }
        }
      }
    }
}
''';

const swapTaigaQuery = r'''
    query ($address: String) {
      swaps(filter: {addressId: {equalTo: $address}}, first: 20, orderBy: TIMESTAMP_DESC){
        nodes {
          id
          inputAmount
          inputAsset
          outputAmount
          outputAsset
          extrinsicId
          block {
            id 
            liquidExchangeRate
          }
          timestamp
        }
      }
      mints(filter: {addressId: {equalTo: $address}}, first: 20, orderBy: TIMESTAMP_DESC){
        nodes {
          id
          inputAmounts
          poolId
          extrinsicId
          block {
            id 
            liquidExchangeRate
          }
          timestamp
        }
      }
      proportionRedeems(filter: {addressId: {equalTo: $address}}, first: 20, orderBy: TIMESTAMP_DESC){
        nodes {
          id
          inputAmount
          poolId
          timestamp
          extrinsicId
          block {
            id 
            liquidExchangeRate
          }
        }
      }
      singleRedeems(filter: {addressId: {equalTo: $address}}, first: 20, orderBy: TIMESTAMP_DESC){
        nodes {
          id
          inputAmount
          poolId
          extrinsicId
          block {
            id 
            liquidExchangeRate
          }
          timestamp
        }
      }
      multiRedeems(filter: {addressId: {equalTo: $address}}, first: 20, orderBy: TIMESTAMP_DESC){
        nodes {
          id
          inputAmount
          poolId
          extrinsicId
          block {
            id 
            liquidExchangeRate
          }
          timestamp
        }
      }
    }
''';

const queryCollaterals = r'''
query {
      collaterals {
        nodes{
          id
          name
          decimals
          depositAmount
          debitAmount
        }
      }
    }
''';
