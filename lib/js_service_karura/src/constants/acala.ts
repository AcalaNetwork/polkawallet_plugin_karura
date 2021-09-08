function AcalaToken(token: string, name: string, decimals: number) {
  return {
    token,
    name,
    decimals,
  };
}

export const tokensForKarura = [
  AcalaToken("KUSD", "Karura Dollar", 12),
  AcalaToken("KSM", "Kusama", 12),
  AcalaToken("LKSM", "Liquid KSM", 12),
  AcalaToken("BNC", "Bifrost", 12),
  //   AcalaToken("XBTC", "ChainX BTC", 8),
  //   AcalaToken("RENBTC", "Ren Protocol BTC", 8),
  //   AcalaToken("POLKABTC", "PolkaBTC", 8),
];

export const nft_image_config = {
  0: "https://acala.subdao.com/nft/metadata/oldFriendMetadata.json",
  1: "https://acala.subdao.com/nft/metadata/karuraCrowdloanWaitlistMetadata.json",
  2: "https://acala.subdao.com/nft/metadata/karuraFamilyMetadata.json",
  3: "https://acala.subdao.com/nft/metadata/karuraFamilyForOKEXEditionMetadata.json",
  4: "https://acala.subdao.com/nft/metadata/karuraFamilyForHuobiPoolEditionmetadata.json",
  5: "https://acala.subdao.com/nft/metadata/karuraFamilyForKuCoinEditionmetadata.json",
};
