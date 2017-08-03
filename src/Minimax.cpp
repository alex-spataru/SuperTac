/*
 * Copyright (c) 2017 Alex Spataru <alex_spataru@outlook.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "Minimax.h"
#include "ComputerPlayer.h"

#include <random>

/**
 * Returns the base score for the minimax function
 */
static int BaseScore (const Board& board) {
    return board.numFields() + 1;
}

/**
 * Returns a random number between \a min and \a max
 */
static int RANDOM (const int min, const int max) {
    std::random_device device;
    std::mt19937 engine (device());
    std::uniform_int_distribution<int> distribution (min ,max);
    return distribution (engine);
}

/**
 * Initializes the internal variables of the class
 */
Minimax::Minimax (QObject *parent) : QObject (parent) {
    m_cpuPlayer = Q_NULLPTR;
}

/**
 * Returns a pointer to the computer player assigned to this class.
 * The minimax code needs some information from the computer player,
 * such as its assigned game board, player ID and opponent ID.
 */
ComputerPlayer* Minimax::cpuPlayer() const {
    return m_cpuPlayer;
}

/**
 * This function shall decide whenever the AI player should do a random move
 * or a "smart" move.
 *|
 * If the function decides that it should make a "smart" move, then it starts
 * another recursive MM cycle to obtain the most optimal AI move.
 *
 * \note This function shall automatically mark the choosen field in the game
 *       board used by the computer player
 */
#include <QTime>
void Minimax::makeAiMove() {
    QTime time;
    time.start();

    Q_ASSERT (cpuPlayer());
    Q_ASSERT (cpuPlayer()->board());

    /* Get board object */
    Board* board = cpuPlayer()->board();

    /* Its not the AI's turn, abort */
    if (cpuPlayer()->board()->currentPlayer() != cpuPlayer()->player())
        return;

    /* Make a random move */
    int n = 10 - RANDOM (1, 10);
    int randomness = cpuPlayer()->randomness();
    if (n < randomness)
        emit decisionTaken (randomMove());

    /* Make a smart move */
    else {
        int move = 0;
        int best = INT_MIN;

        foreach (int field, board->availableFields()) {
            Board copy = *board;
            copy.selectField (field);
            int minimaxScore = minimax (copy, 0, 0, INT_MIN, INT_MAX);

            if (minimaxScore >= best) {
                move = field;
                best = minimaxScore;
            }
        }

        emit decisionTaken (move);
    }

    qDebug() << "Made AI decision in" << time.elapsed() << "ms";

    /* Notify that we have finished thinking */
    emit finished();
}

/**
 * Changes the computer player assigned to this class
 */
void Minimax::setComputerPlayer (ComputerPlayer *player) {
    Q_ASSERT (player);
    m_cpuPlayer = player;
}

/**
 * Returns a randomly-choosen field from the given \a board
 */
int Minimax::randomMove () {
    Board* board = cpuPlayer()->board();
    int n = RANDOM (1, board->availableFields().count());
    return board->availableFields().at (n - 1);
}

/**
 * Executes the Minimax algorithm in order to find the most optimal move that can be
 * choosen by the AI player
 */
int Minimax::minimax (Board &board, const int depth,
                      const int node, int alpha, int beta) {
    board.updateGameState();

    /* Meh, no one wins */
    if (board.gameDraw())
        return 0;

    /* Somebody wins, calculate score */
    else if (board.gameWon()) {
        if (board.winner() == cpuPlayer()->player())
            return BaseScore (board) - depth;

        return -BaseScore (board) + depth;
    }

    /* Iterate over the fields and get the best score */
    else {
        int isMax = board.currentPlayer() == cpuPlayer()->player();
        int best = isMax ? INT_MIN : INT_MAX;

        for (int i = 0; i < board.availableFields().count(); ++i) {
            Board copy = board;
            copy.selectField (copy.availableFields().at (i));
            int mm = minimax (copy, depth + 1, node * 2 + i, alpha, beta);

            if (isMax) {
                best = qMax (best, mm);
                alpha = qMax (best, alpha);

                if (beta <= alpha)
                    return alpha;
            }

            else {
                best = qMin (best, mm);
                beta = qMin (best, beta);

                if (beta <= alpha)
                    return beta;
            }
        }

        return best;
    }

    /* We should not reach this code */
    return 0;
}
