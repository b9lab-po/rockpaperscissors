pragma solidity 0.4.24;

contract RockPaperScissors {
    enum Move {NONE, ROCK, PAPER, SCISSORS}
    enum Winner {NONE, PLAYERONE, PLAYERTWO, DRAW}

    uint playersInGame = 0;

    struct Players {
        address player;
        uint256 amount;
        bytes32 hashedMove;
        Move move;
        bool unhashed;
    }

    struct WinnersTable {
        uint score;
    }

    event LogNewScore(address player, uint score);
    event LogWinner(address player, uint256 amount);
    event LogExit(address player);

    mapping(address => WinnersTable) winnersTable;

    Players[2] public players;

    modifier validatePlayers () {
        require(playersInGame <= 2, "There is already two players in the game!");
        _;
    }

    modifier validateGame () {
        require(playersInGame == 2, "Game require two players!");
        require(players[0].unhashed, "Player 1 must unhash his move!");
        require(players[1].unhashed, "Player 2 must unhash his move!");
        _;
    }

    function makeMove(bytes32 hashedMove) public payable validatePlayers {
        players[playersInGame].player = msg.sender;
        players[playersInGame].amount = msg.value;
        players[playersInGame].hashedMove = hashedMove;
        playersInGame += 1;
    }

    function unHashMove(Move move, string password) public {
        uint playerIndex = getPlayerIndex(msg.sender);
        require(playerIndex < 2, "You are not in the game!");
        require(players[playerIndex].hashedMove == hashMove(move, password), "Wrong password or move!");

        players[playerIndex].move = move;
        players[playerIndex].unhashed = true;
    }

    function getPlayerIndex(address player) private view returns (uint) {
        for(uint i = 0; i < 2; i++) {
            if(players[i].player == player) {
                return i;
            }
        }
        return 3;
    }

    function calculateScore(Move playerOneMove, Move playerTwoMove) private pure returns (Winner) {
        if(playerOneMove == Move.NONE || playerTwoMove == Move.NONE) {
            return Winner.NONE;
        } else if(playerOneMove == playerTwoMove) {
            return Winner.DRAW;
        } else {
            if(Move.ROCK == playerOneMove) {
                if(Move.PAPER == playerTwoMove) {
                    return Winner.PLAYERTWO;
                } else {
                    return Winner.PLAYERONE;
                }
            } else if(Move.PAPER == playerOneMove) {
                if(Move.SCISSORS == playerTwoMove) {
                    return Winner.PLAYERTWO;
                } else {
                    return Winner.PLAYERONE;
                }
            } else {
                if(Move.ROCK == playerTwoMove) {
                    return Winner.PLAYERTWO;
                } else {
                    return Winner.PLAYERONE;
                }
            }
        }
    }

    function incrementScore(uint playerIndex) private {
        WinnersTable storage newScore = winnersTable[players[playerIndex].player];
        newScore.score += 1;
        emit LogNewScore(players[playerIndex].player, newScore.score);
    }

    function play() public validateGame {
        Winner winner = calculateScore(players[0].move, players[1].move);
        playersInGame = 0;
        uint256 totalAmount = players[0].amount + players[1].amount;

        if(Winner.DRAW == winner) {
            uint256 halfAmount = (totalAmount - (totalAmount % 2)) / 2;
            emit LogWinner(players[0].player, halfAmount);
            emit LogWinner(players[1].player, halfAmount);
            players[0].player.transfer(halfAmount);
            players[1].player.transfer(halfAmount);
        } else if(Winner.PLAYERONE == winner) {
            incrementScore(0);
            emit LogWinner(players[0].player, totalAmount);
            players[0].player.transfer(totalAmount);
        } else if(Winner.PLAYERTWO == winner) {
            incrementScore(1);
            emit LogWinner(players[1].player, totalAmount);
            players[0].player.transfer(totalAmount);
        } else { // NONE
            players[0].player.transfer(players[0].amount);
            players[1].player.transfer(players[1].amount);
        }
    }

    function exitGame() public {
        uint playerIndex = getPlayerIndex(msg.sender);
        playersInGame -= 1;
        emit LogExit(players[playerIndex].player);
        players[playerIndex].player.transfer(players[playerIndex].amount);
    }

    function hashMove(Move move, string password) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(move, password));
    }
}