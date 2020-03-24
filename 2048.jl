# 2048 Game Server
using Test
using Printf
using SparseArrays
# function move
function move(line, direction)

    # 計算array長度
    lineLen = length(line)
    # 取出array裡非零元素
    nonZeroLine = line[line .> 0]  # why .> ??

    # 補零
    if direction > 0
        newLine=[nonZeroLine;zeros(Int64,lineLen-length(nonZeroLine))] # 改分號";"
    elseif direction < 0
        newLine=[zeros(Int64,lineLen-length(nonZeroLine)); nonZeroLine] # 改分號";"
    end

    return newLine
end

# print(move([1,0,2,3], 1))

# function merge
function merge(line)

    addScore=0
    lineLen=length(line)
    for idx=1:lineLen
        nextidx=idx+1;
        if nextidx<=lineLen
            if line[idx]==line[nextidx]

                addScore=addScore+line[idx]
                line[idx]=line[idx]*2
                line[nextidx]=0
            end

        end
    end

    return line,addScore
end


# function move + merge
function moveMerge(line,direction)

	line=move(line,direction)
	line,addScore=merge(line)
	line=move(line,direction)

	return line,addScore
end


function boardMove(board,direction)

	if direction==0
		return board, 0
	end


	newBoard=copy(board)
	addScore=0
	for rowIdx=1:size(newBoard,abs(direction))
		line=getLine(newBoard,abs(direction),rowIdx)
		newLine,score=moveMerge(line,direction)
		addScore=addScore+score
		newBoard=setLine(newBoard,abs(direction),rowIdx,newLine)
	end

	return newBoard,addScore
end
# board=[4 0 2 2; 0 0 0 8; 16 4 0 0; 16 0 0 0]
# 從 board 中取出一列
function getLine(board,dim,index)

	if dim==1

		return board[index,:]

	elseif dim==2

		return reshape(board[:,index],size(board,dim))

	end

end


# 傳回board
function setLine(board,dim,index,line)

	if dim==1

		board[index,:]=line

	elseif dim==2

		board[:,index]=reshape(line,1,size(board,dim))

	end

	return board

end

# [0 0 0 0;0 0 0 0;0 0 0 0;0 0 0 0] turn into "0000000000000000"
function printBoard(board)
    boardStr = ""
    for rowInd = 1: size(board, 1)
        for colInd = 1: size(board, 2)
            tmpStr=@sprintf("%6d",board[rowInd,colInd])
            boardStr = string(boardStr, tmpStr)
        end
        boardStr = string(boardStr, "\n")
    end
    return boardStr
end


function humanPlayer(board)

    str="請輸入方向(上(K),下(J),左(H),右(L),離開(Q)):"

    print(str)

    return chomp(readline())
end


 #=function getFreeTiles(board)
    n = 0
    for i= 1: size(board, 1)
        for j= 1: size(board, 2)
            if board[i,j] == 0
                n = n + 1
            end
        end
    end
    return n
end

=#

# getFreeTiles([1,2,3,0,0,0])
# board=[4 0 2 2; 0 0 0 8; 16 4 0 0; 16 0 0 0]
# getFreeTiles(board)


function addTile(board)

    flatBoard=reshape(board,size(board,1)*size(board,2))

    # 選出空白格子的index
    freeTileIndex=findall(flatBoard.==0)

    # 從1到length(freeTileIndex)隨機選出一個整數newTileIndex
    # 即，freeTileIndex[newTileIndex]就是board要放上新數字的座標
    newTileIndex=rand(1:length(freeTileIndex))

    # 建立一個新的陣列放2和4
    tileToChoose=[ones(Int64,9).*2;4] # 2,2,2,2,2,2,2,2,2,4 改分號

    # 同樣也隨機選一個整數，用來選取tileToChoose陣列的其中一個值
    newTile=rand(1:length(tileToChoose))

    @assert(flatBoard[freeTileIndex[newTileIndex]]==0)

    # 把選到的值放到選到的陣列上
    flatBoard[freeTileIndex[newTileIndex]]=tileToChoose[newTile]

    #return the new board
    return reshape(flatBoard,size(board,1),size(board,2))

end


function initBoard(boardSize=4)

    # Initialize a board

    board=zeros(Int64,boardSize,boardSize)

    for i=1:3
        board=addTile(board)
    end

    return board

end


function humanPlayer(board)

	promptStr="Enter your next move:"

	promptStr="請輸入方向(上(K),下(J),左(H),右(L),離開(Q)):"

	print(promptStr)

	input=chomp(readline())

	if input=="H" || input=="h"
		moveDir=1
	elseif input=="L" || input=="l"
		moveDir=-1
	elseif input=="K" || input=="k"
		moveDir=2
	elseif input=="J" || input=="j"
		moveDir=-2
	elseif input=="Q" || input=="q"
		moveDir= "QuitGame"
	else
		moveDir=0

	end

	return moveDir

end


function getFreeTiles(board)

	i,j,v=findnz(board.==0)

	return length(i)

end


function isMoved(board,nextBoard)

	# Check whether the board is moved

	return !(board==nextBoard)
end


function getLegalMoves(board)

	possibleMoves=[1,-1,2,-2]

	# Construct an array for legal moves
	legalMoves=[]
	nextScores=[]

	for i=1:length(possibleMoves)
		newBoard,score=boardMove(board,possibleMoves[i])
		if isMoved(board,newBoard)

			legalMoves=[legalMoves,possibleMoves[i]]
			nextScores=[nextScores,score]
		end
	end


	return legalMoves,nextScores

end





function gameState(board)

	if max(board...)==2048
		return "WinGame"
	end

	if length(getLegalMoves(board))>0
		return "ContinueGame"
	else
		return "LoseGame"
	end

end


function gameLoop(player::Function)

	board=initBoard()
	totalSteps=0
	gameScore=0

	while gameState(board)== "ContinueGame"


		println(printBoard(board))
		@printf("current score: %d\n", gameScore)

		moveDir=player(board)

		if moveDir=="QuitGame"
			break
		end


		nextBoard,addScore=boardMove(board,moveDir)

		gameScore=gameScore+addScore

		if isMoved(board,nextBoard)>0
			nextBoard=addTile(nextBoard)
		end


		# Judge whether the game should continue

		if gameState(board)=="WinGame"
			println("Congrats! You Win!")
			break
		elseif gameState(board)=="LoseGame"
			println("Good effort, but try again")
			break
		end


		board=nextBoard

		totalSteps=totalSteps+1


	end

	@printf("total elapsed steps: %d\n",totalSteps)
	@printf("final gamescore: %d\n",gameScore)
end




gameLoop(humanPlayer)
# test 
