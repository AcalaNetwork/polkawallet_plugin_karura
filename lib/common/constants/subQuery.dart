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
        extrinsic {
          id
          timestamp
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
const swapQuery = r'''
  query ($account: String) {
    dexActions(filter: {accountId: {equalTo: $account}},
      orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        type
        data
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
const dexStakeQuery = r'''
  query ($account: String) {
    incentiveActions(filter: {accountId: {equalTo: $account}},
      orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        type
        data
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
const homaQuery = r'''
  query ($account: String) {
    homaActions(filter: {accountId: {equalTo: $account}},
      orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        type
        data
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
