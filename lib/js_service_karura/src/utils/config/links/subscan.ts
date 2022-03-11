export default {
  chains: {
    Acala: "acala",
    Karura: "karura",
  },
  create: (chain: string, path: string, data: any) => `https://${chain}.subscan.io/${path}/${data.toString()}`,
  isActive: true,
  paths: {
    address: "account",
    block: "block",
    council: "council",
    extrinsic: "extrinsic",
    proposal: "democracy_proposal",
    referendum: "referenda",
    techcomm: "tech",
    treasury: "treasury",
  },
  url: "https://subscan.io/",
};
