const EKLGame = artifacts.require("EKLGame");

module.exports = function (deployer) {
  deployer.then(async () => {
    try {
      const game = await deployer.deploy(
        EKLGame,
        "0xf24263d1Aec24366964060dbfa218086c7Bd27E9"
      );

      await game.setNFT(
        "0x9fe26445E2f4F7c30433505E7617b41704017CF6", //NFT
        600,
        [
          "0xcC83B44ea968DaE4EC562F0E94fB37937b88db41",
          "0xcC83B44ea968DaE4EC562F0E94fB37937b88db41",
        ],
        [1, 2],
        true
      );
    } catch (error) {
      console.log(error);
    }
  });
};
