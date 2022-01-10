const Map<String, String> enDex = {
  'acala': 'Acala Defi Hub',
  'airdrop': 'Airdrop',
  'transfer': 'Transfer',
  'receive': 'Receive',
  'dex.title': 'Swap',
  'dex.pay': 'Pay',
  'dex.receive': 'Receive',
  'dex.rate': 'Price',
  'dex.route': 'Route',
  'dex.slippage': 'Slippage Tolerance',
  'dex.slippage.error': 'Valid Slippage: 0.1%~49.9%',
  'dex.tx.pay': 'Pay with',
  'dex.tx.receive': 'Receive',
  'dex.min': 'Minimum received',
  'dex.max': 'Maximum sold',
  'dex.fee': 'Liquidity provider fee',
  'dex.impact': 'Price impact',
  'dex.lp': 'Liquidity',
  'dex.swap': 'Swap',
  'dex.addLiquidity': 'Add Liquidity',
  'dex.removeLiquidity': 'Remove Liquidity',
  'dex.addProvision': 'Add Provision',
  'boot.title': 'Bootstrap',
  'boot.provision': 'Provisioning',
  'boot.enabled': 'Enabled',
  'boot.provision.info':
      'The pool will start when the following conditions are met:',
  'boot.provision.condition.1': 'The liquidity target reaches',
  'boot.provision.condition.2': 'Time after',
  'boot.provision.or': 'or',
  'boot.provision.met': 'met',
  'boot.provision.add': 'Add Provision',
  'boot.ratio': 'Current ratio',
  'boot.total': 'Total',
  'boot.my': 'My Liquidity Provision',
  'boot.my.est': 'Est.',
  'boot.my.share': 'Share',
  'boot.add': 'Add',
  'loan.title': 'Mint aUSD',
  'loan.title.KSM': 'Mint kUSD',
  'loan.borrowed': 'Owed',
  'loan.collateral': 'Collateral',
  'loan.ratio': 'Collateral Ratio',
  'loan.ratio.info':
      '\nThe ratio between the USD value of your vault collateral and the amount of aUSD minted (collateral value in USD / aUSD minted).\n',
  'loan.ratio.info.KSM':
      '\nThe ratio between the USD value of your vault collateral and the amount of kUSD minted (collateral value in USD / kUSD minted).\n',
  'loan.mint': 'Mint',
  'loan.payback': 'Payback',
  'loan.deposit': 'Deposit',
  'loan.deposit.col': 'Deposit collateral',
  'loan.withdraw': 'Withdraw',
  'loan.withdraw.all': 'Withdraw all collateral in the meanwhile',
  'loan.create': 'Create Vault',
  'loan.liquidate': 'Liquidate',
  'liquid.price': 'Liquidation Price',
  'liquid.ratio': 'Liquidation Ratio',
  'liquid.ratio.require': 'Required Ratio',
  'liquid.price.new': 'New Liquidation Price',
  'liquid.ratio.current': 'Current Ratio',
  'liquid.ratio.new': 'New Collateral Ratio',
  'collateral.price': 'Price',
  'collateral.price.current': 'Current Price',
  'collateral.interest': 'Stability Fee',
  'collateral.require': 'Required',
  'borrow.limit': 'Mint Limit',
  'borrow.able': 'Able to MInt',
  'withdraw.able': 'Able to Withdraw',
  'loan.amount': 'Amount',
  'loan.amount.debit': 'How much would you like to mint?',
  'loan.amount.collateral': 'How much would you deposit as collateral?',
  'loan.max': 'Max',
  'loan.txs': 'History',
  'loan.warn':
      'Debt should be greater than 1aUSD or payback all, this action will have 1aUSD debt left. Are you sure to continue?',
  'loan.warn.KSM':
      'Debt should be greater than 1kUSD or payback all, this action will have 1kUSD debt left. Are you sure to continue?',
  'loan.warn.back': 'Back to modify',
  'loan.my': 'My Vaults',
  'loan.incentive': 'Earn',
  'loan.activate': 'Activate Rewards',
  'loan.activate.1': 'Click Here',
  'loan.activate.2': 'to activate your rewards.',
  'loan.close': 'Close Vault',
  'loan.close.dex': 'Close Vault by Swapping Collateral',
  'loan.close.dex.info':
      'Part of your collateral will be sold on Swap to pay back all outstanding kUSD. The remaining collateral will be returned to your account. Are you sure to proceed?',
  'loan.close.receive': 'Estimated Receive',
  'txs.action': 'Action',
  'payback.small': 'The remaining debt is too small',
  'earn.title': 'Earn',
  'earn.dex': 'LP Staking',
  'earn.loan': 'Collateral Staking',
  'earn.add': 'Add Liquidity',
  'earn.remove': 'Remove Liquidity',
  'earn.reward.year': 'Annualized Rewards',
  'earn.fee': 'Swap Fee',
  'earn.fee.info':
      '\nTrading fees will be automatically received when you remove liquidity.\n',
  'earn.pool': 'Pool',
  'earn.stake.pool': 'Staking Pool',
  'earn.share': 'Share',
  'earn.reward': 'Rewards',
  'earn.available': 'Available',
  'earn.stake': 'Stake',
  'earn.unStake': 'Unstake',
  'earn.unStake.info':
      'Note: unstake LP tokens before program ends will claim earned rewards & lose Loyalty Bonus.',
  'earn.staked': 'Staked',
  'earn.claim': 'Claim Rewards',
  'earn.claim.info':
      'Note: Claim now will forego your Loyalty Bonus. Are you sure to continue?',
  'earn.apy': 'APR',
  'earn.apy.0': 'APR w/o Loyalty',
  'earn.incentive': 'Mining',
  'earn.saving': 'Interest',
  'earn.loyal': 'Loyalty Bonus',
  'earn.loyal.end': 'loyalty program ends',
  'earn.loyal.info':
      '\nIf rewards are kept in the pool until the end of the program, there\'s an extra bonus.\n',
  'earn.withStake': 'with stake',
  'earn.withStake.txt':
      '\nwhether to stake added LP Tokens to obtain rewards.\n',
  'earn.withStake.all': 'stake all',
  'earn.withStake.all.txt': 'stake all your LP Tokens',
  'earn.withStake.info': 'Stake LP Tokens for Liquidity Mining Rewards',
  'earn.fromPool': 'with auto unstake',
  'earn.fromPool.txt':
      '\nAutomatically unstake LP Tokens and remove liquidity based on the input amount.\n',
  'earn.DepositDexShare': 'Stake LP',
  'earn.WithdrawDexShare': 'Unstake LP',
  'earn.ClaimRewards': 'Claim Rewards',
  'earn.PayoutRewards': 'Payout Rewards',
  'homa.title': 'Liquid',
  'homa.mint': 'Mint',
  'homa.redeem': 'Redeem',
  'homa.fast': 'Fast Redeem',
  'homa.now': 'or you can use the',
  'homa.era': 'Redeem in Era',
  'homa.confirm': 'Confirm',
  'homa.unbond': 'Wait for Unbounding',
  'homa.pool': 'Staking Pool',
  'homa.pool.cap': 'Pool Cap',
  'homa.pool.bonded': 'Total Bonded',
  'homa.pool.ratio': 'Bond Ratio',
  'homa.pool.min': 'Min bond',
  'homa.pool.redeem': 'Min redeem',
  'homa.pool.issuance': 'Issuance',
  'homa.pool.cap.error': 'Exceeds the staking pool cap.',
  'homa.pool.low': 'Insufficient pool balance',
  'homa.user': 'My DOT Redeem',
  'homa.user.unbonding': 'Unbonding',
  'homa.user.time': 'Unlock Time',
  'homa.user.blocks': 'Blocks',
  'homa.user.redeemable': 'Redeemable',
  'homa.user.stats': 'My Stats',
  'homa.user.ksm': 'Free KSM',
  'homa.user.unlocking': 'Unlocking KSM',
  'homa.user.lksm': 'Free LKSM',
  'homa.mint.profit': 'Estimated Profit / Era',
  'homa.mint.warn':
      'LKSM Phase 1 uses proxy staking, and redemption is NOT available until the next Phase. Read more',
  'homa.mint.warn.here': ' here',
  'homa.redeem.fee': 'Claim Fee',
  'homa.redeem.era': 'Current Era',
  'homa.redeem.period': 'Unbonding Period',
  'homa.redeem.day': 'Days',
  'homa.redeem.free': 'Pool',
  'homa.redeem.unbonding': 'Max Unbonding Period',
  'homa.redeem.receive': 'Expected to receive',
  'homa.redeem.cancel': 'Cancel',
  'homa.redeem.pending': 'You have a pending redeem request',
  'homa.redeem.replace':
      'By sending a new redeem request, the pending one will be canceled.',
  'homa.redeem.hint':
      'Cancel the pending redeem KSM request and receive your LKSM. Are you sure to continue?',
  'homa.Minted': 'Mint',
  'homa.Redeemed': 'Redeemed',
  'homa.RedeemRequest': 'Redeem Request',
  'homa.RedeemRequestCancelled': 'Cancel Redeem',
  'homa.RedeemedByFastMatch': 'Fast Redeemed',
  'homa.WithdrawRedemption': 'Claim Redeemed',
  'homa.RedeemedByUnbond': 'Redeemed',
  'homa.unbonding': 'Unbondings',
  'homa.claimable': 'Claimable',
  'homa.claim': 'Claim',
  'tx.fee.or': 'or equivalent in other tokens',
  'nft.title': 'NFTs',
  'nft.testnet': 'Mandala testnet badge',
  'nft.transfer': 'Transfer',
  'nft.burn': 'Burn',
  'nft.quantity': 'Quantity',
  'nft.Transferable': 'Transferable',
  'nft.Burnable': 'Burnable',
  'nft.Mintable': 'Mintable',
  'nft.Unmintable': 'Unmintable',
  'nft.ClassPropertiesMutable': 'Mutable',
  'nft.All': 'All',
  'nft.name': 'Name',
  'nft.description': 'Description',
  'nft.class': 'ClassID',
  'nft.publisher': 'Publisher',
  'nft.deposit': 'Deposit',
  'candy.title': 'Candy Claim',
  'candy.claim': 'Claim',
  'candy.amount': 'Candies to claim',
  'candy.claimed': 'Claimed',
  'cross.chain': 'To Chain',
  'cross.xcm': 'Cross Chain',
  'cross.chain.select': 'Select Network',
  'cross.exist': 'dest chain ED',
  'cross.exist.msg':
      '\nED (existential deposit): The minimum amount that an account should have to be deemed active.\n',
  'cross.fee': 'dest chain transfer fee',
  'cross.warn': 'Warning',
  'cross.edit': 'Edit To Address',
  'cross.warn.info':
      'Editing cross-chain destination address is not recommended.\nAdvanced users only.',
  'transfer.exist': 'existential deposit',
  'transfer.fee': 'estimated transfer fee',
  'warn.fee': 'The transaction may fail due to insufficient KAR balance.',
  'v3.switchDefi': 'Switch to Defi',
  'v3.switchBack': 'Switch Back',
  'v3.totalBalance': 'Total Balance',
  'v3.myDefi': 'My Defi',
  'v3.totalStaked': 'Total Staked',
  'v3.total': 'Total',
  'v3.myStats': 'My Stats',
  'v3.unnonding': 'Unnonding',
  'v3.claim': 'Claim',
  'v3.createVaultText': 'Create a vault to start your DeFi adventure',
};
