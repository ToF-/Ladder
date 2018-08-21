# Ladder
## Introduction
A "word ladder" is a list of words having the following characteristics
- all words have the same number of letters
- each word is unique in the list
- each word is distinct from its predecessor in the list by one letter

Here are some examples :
- *dog dot cot cat*
- *warm ward card cord cold*
- *grape grace brace bract brant brunt bruit fruit*


In this kata, you are given a list of words, such as [this one](http://www-personal.umich.edu/~jlawler/wordlist.html), and your job is to write a program that prints the shortest word ladder between two given words. 

The program will read 3 arguments on the command line:

- the name of the file containing the word list
- a starting word 
- the target word

The program will then print the shortest ladder between the starting and the target words, or print nothing if there is no possible ladder between the starting and target words.

Here's the main program:
```Haskell
import System.Environment

main = getArgs >>= checkArgs >>= readWords >>= printLadder
    where
    checkArgs args | length args == 3 = return args
    checkArgs args | otherwise       = error "usage: ladder <wordlistfile> <start> <end>"

    readWords [f,s,t] = readFile f >>= \cs -> return ( filter (\w -> length w == length s) $ words cs, s, t)

    printLadder (ws,s,t) = putStrLn $ unwords $ ladder ws s t
```
The definition of the function 
```Haskell
ladder :: [String] -> String ->String -> [String]
```
is missing: let's create it, one step at a time.

## 1. Neighbor
Two words are said to be *neighbors* if the have the same number of letters, and differ only by one letter.
Write a function
```Haskell
neighbor :: String -> String -> Bool
```
that evaluates to `True` if its arguments are neighbors, `False` otherwise. Here are some examples of use of this function:
```Haskell
neighbor "cat" "dog" ⏎
False
neighbor "cat" "bat" ⏎
True
neighbor "cat" "cot" ⏎
True
neighbor "cat" "cob" ⏎
False
neighbor "cat" "cab" ⏎
True
neighbor "dog" "do" ⏎
False
neighbor "at" "cat" ⏎
False
```
*If your definition is using recursion: Can you think of an alternative definiton that would use a high order function?*

*If your definition is using high order functions: Can you think of an alternative definition that would use recursion?*
## 2. Neighbors
Our next step on the ladder is to keep track of which words neighbor a given word. Such connection between two words deserves a type alias:
```Haskell
type Neighbors = (String,String)
```
Write a function
```Haskell
neighbors :: [String] -> String -> [Neighbors]
```
that given a list of words `ws` and a word `w`, yields a list `[(n,w),(m,w),..,(z,w)]` of all the neighbors to `w` in `ws`.

Here's an example of use of this function:
```Haskell
:set +t ⏎

let ws = words "bag bat bog dog fog" ⏎
ws :: [String]

neighbors ws "fog" ⏎
[("bog","fog"),("dog","fog")]
it :: [Neighbors]
```
*What does the expression* `map (neighbors ws) ws` *yield?*
## 3. Path
With the help of standard functions such as `lookup` on a list of `Neighbor`s,it is possible to follow a certain *path* from word to word. Write a function:
```Haskell
path :: String -> [Neighbors] -> [String]
```
that given a word `w` and a list of pairs of words `ns`, looks up in that list for the word `x` that is attached to `w`, then for the word `y` that is attached to `x`  and so on, until the next word cannot be found in the list. The result of the function is the list `[w,x,y,..,z]` of the all the words found on the path.

Here's an example of use of this function:
```Haskell
let ns = [("cat","bat"),("bat","bag"),("bag","bog"),("bog","dog"),("dog","***")] ⏎
path "cat" ns ⏎
["cat","bat","bag","bog","dog"]
path "foo" ns ⏎
[]
```
*For this function to always terminate, what should be true about the list given as second argument?*
## 4. Neighbors of neighbors
What happens if, armed with the functions we have so far, we try to find neighbors of neighbors? Let's try.
```Haskell
let ws = words "bag bat bog cat cog dog fog" ⏎
neighbors ws "fog" ⏎
[("bog","fog"),("cog","fog"),("dog","fog")]
concat $ map (neighbors ws) $ map fst $ neighbors ws "fog" ⏎
[("bag","bog"),("cog","bog"),("dog","bog"),("fog","bog"),("bog","cog"),("dog","cog"),("fog","cog"),("bog","dog"),("cog","dog"),("fog","dog")]
```
*Can you replace* `concat $ map (neighbors ws) $ map fst` *with a more concise expression?*

*Can we use this expression to find a ladder between the words "cat" and "dog" in the example above ?*

*What about a ladder between the words "bog" and "fog" ?*

## 5. Explore
If we want to explore a list of words looking for a ladder starting with `s` and ending with `t`, we can proceed as follow:
- look for all the pairs `[(n,t),(m,t),..,(o,t)]` where `[n,m,..,o]` are neighbors of `t`
- look for all the pairs `[(a,n),(b,n),..,(c,n),(d,m),(e,m),..(f,m),(g,o),(h,o),..,(i,o)]`, where `[a,b,..,c]`, `[d,e,..,f]` and `[g,h,..,i]` are neighbors of respectively `[n,m,..,o]`. 
- continue this process until we find the word `s`in our list.
However, due to the fact that the `neighbor` relationship is symmetric, for the search to terminate, two properties should hold about the list of pairs we are building:
- there is a pair `(t,𝞊)`, such that no pair `(𝞊,x)` exist in the list. `t` is called the *target* word.
- if a pair `(x,y)` exist in the list, there can be no other pair `(x,z)` in the list.

In other words the list of neighbor pairs represent a *tree* in which the *target* word is the root, and every other word is directly or indirectly connected to the *target* word. 
```Haskell
type Tree = [Neighbors]
```
In order to know which new neighbor should be explored at a given time, we have to take into account the current *tree* of words we have built so far. The result of exploring these neighbors yields a list of new words to explore, and a new tree, containing all the existing pairs, plus the newly found pairs:
```Haskell
type State =([String],Tree)
```
Write a function
```Haskell
explore :: [String] -> String -> Tree -> State
```
that, given a word list `ws`, a word `s` and a tree `t`, will produce a state `([w,x,..,y],t')` such that:
- `[w,x,..,y]` are the neighbors to `s` that are not already present in `t`.
- `t' == t ++ [(w,s),(x,s),..,(y,s)]` 
Here are examples of use of the function:
```Haskell
let ws = words "bag bat bog cat cog dog fog" ⏎

explore ws "fog" [("fog","")] ⏎
(["bog","cog","dog"],[("fog",""),("bog","fog"),("cog","fog"),("dog","fog")])

explore ws "bag" (snd it) ⏎
(["bat"],[("fog",""),("bog","fog"),("cog","fog"),("dog","fog"),("bat","bag")])

explore ws "fog" (snd it) ⏎
([],[("fog",""),("bog","fog"),("cog","fog"),("dog","fog"),("bat","bag")])
```
## 6. Breadth Search
Finding the shortest path between two words involve a *breadth first search* strategy, meaning that all the neighbors of a word should have been visited before the neighbors of these neighbors are. The search process maintains a *queue* of wordt to visit, and each exploration step extracts the word at the top of the queue, and add the neighbors of this word at the end of the queue.
The process stops either when the list is empty, or when the head of the queue is the word that was sought for.
 
Write a function 
```Haskell
breadthSearch :: [String] -> State -> State
```
that given a list of word `ws`, an a state `([v,w,..,y],t)`, returns a new state `([w,..y,n,m,..,o],t')` such that:
- the words `[n,m,..,o]` are neighbors of `v` in `ws` that are not already present in `t`
- the new tree `t'` has all the neighbor pairs from `t` plus the neighbor pairs `[(n,v),(m,v),..,(o,v)]`

Here are examples of use of this function:
```Haskell
let ws = words "bag bat bog cat cog dog fog"

breadthSearch ws (["fog"],[("fog","")])
(["bog","cog","dog"],[("fog",""),("bog","fog"),("cog","fog"),("dog","fog")])

breadthSearch ws it
(["cog","dog","bag"],[("fog",""),("bog","fog"),("cog","fog"),("dog","fog"),("bag","bog")])

breadthSearch ws it
(["dog","bag"],[("fog",""),("bog","fog"),("cog","fog"),("dog","fog"),("bag","bog")])

breadthSearch ws it
(["bag"],[("fog",""),("bog","fog"),("cog","fog"),("dog","fog"),("bag","bog")])

breadthSearch ws it
(["bat"],[("fog",""),("bog","fog"),("cog","fog"),("dog","fog"),("bag","bog"),("bat","bag")])

breadthSearch ws it
(["cat"],[("fog",""),("bog","fog"),("cog","fog"),("dog","fog"),("bag","bog"),("bat","bag"),("cat","bat")])

breadthSearch ws it
([],[("fog",""),("bog","fog"),("cog","fog"),("dog","fog"),("bag","bog"),("bat","bag"),("cat","bat")])
```
*What should be added to the function definition for the function to be total ?*

*What initial state would allow for a breadth first search of word `s` starting from `t` ?*
### 7. Ladder 
In order to determine the shortest ladder between two words from a list, we have to process with our `breadthSearch` function, starting with an inital state set to `([t],[(t,"")])` where `t` is the last word of the ladder, and then recurse until one of two things happen:
- the list of words to visit is empty, which means that there is no possible ladder
- the first word in the list is the starting word in the ladder

Write a function:
```Haskell
ladder :: [String] -> String -> String -> [String]
```
that given a list of words `ws`, a starting word `s`, a target word `t`, yields:
- the list representing the shortest ladder between `s` and `t`
- the empty list if no ladder can be found

Here are some examples of use of this function:
```Haskell
let ws = words "bag bat bog cat cog dog fog"

unwords $ ladder ws "bag" "fog"
"bag bog fog"

unwords $ ladder ws "cat" "dog"
"cat bat bag bog dog"

unwords $ ladder ws "foo" "dog"
""
unwords $ ladder ws "dog" "qux"
""

fmap (filter (\w -> length w == 4) . words) $ readFile "wordlist.txt" ⏎
ladder ws "wood" "iron" ⏎
["wood","good","goad","grad","brad","bran","iran","iron"]
```
Now our program is complete! Here's an example of use:
```
>runhaskell Ladder.hs wordlist.txt bread apple
bread tread triad trial trill twill swill still stile stole atole amole ample apple
```


