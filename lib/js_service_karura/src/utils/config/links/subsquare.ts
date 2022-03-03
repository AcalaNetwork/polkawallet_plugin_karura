export default {
  chains: {
    Acala: "acala",
    Karura: "karura",
  },
  create: (chain: string, path: string, data: any) => `https://${chain}.subsquare.io/${path}/${data.toString()}`,
  isActive: true,
  paths: {
    proposal: "democracy/proposal",
    referendum: "democracy/referendum",
    treasury: "treasury/proposal",
  },
  url: "https://subsquare.io/",
};
