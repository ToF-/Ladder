import Data.List

type Edge = (String,String)
type Tree = [Edge]
type State = (Queue,Tree)
type Dict = [String]
type Queue = [String]

neighbor :: String -> String -> Bool
neighbor "" _ = False
neighbor _ "" = False
neighbor (c:cs) (d:ds) | c/=d = cs == ds
                       | otherwise = neighbor cs ds

neighbors :: String -> Dict -> Tree
neighbors w ws = [(n,w) | n <- ws, neighbor w n]

path :: String -> Tree -> [String]
path w t = case lookup w t of
    Nothing -> []
    Just n  -> w : path n t

search :: Dict -> State -> State
search _ ([],t) = ([],t)
search ws (vs,t) = search ws' (vs',t')
    where
    w   = head vs
    vs' = tail vs ++ ns
    ts  = neighbors w ws
    ns  = map fst ts
    ws' = ws \\ ns
    t'  = t ++ ts

initial :: String -> State
initial s = ([s],[(s,"")]) 
