{-# LANGUAGE DoAndIfThenElse #-}

module Helpers where

import Control.Exception
import Control.DeepSeq (force)
import System.Directory
import System.Posix.User
import Data.List (isInfixOf)
import Category

delimeter = "---------------------------------------------"

-- not portable, posix stuff
greetUserInPosixWay = do
        user <- getRealUserID >>= getUserEntryForID
        putStrLn $ "Hi, " ++ (userName user)

-- for non posix stuff
greetHardcodedUser = putStrLn $ "Hi, User!"

greetUser os = if os == "windows" then greetHardcodedUser else greetUserInPosixWay >> putStrLn delimeter

runShell = do   
        startShell     
        content <- getCurrentDirectory >>= getDirectoryContents
        files <- getListOfFiles $ filterDotsInFilePaths content
        -- debug output
        -- print files
        dirs <- getListOfDirs $ filterDotsInFilePaths content
        -- debug output
        -- print dirs
        allFiles <- getListOfFilesRecursively $ filterDotsInFilePaths content
        categories <- categorizedFiles allFiles
        print categories
        -- more to come
        exitShell

startShell = putStrLn "Octo Shell starting..." >> putStrLn delimeter

exitShell = putStrLn delimeter >> putStrLn "Octo Shell exiting..."

exit = putStrLn delimeter >> putStrLn "Couldn't parse command [Try to type 'start']"

-- dummy version of categorizer
categorizeFile :: FilePath -> Category
categorizeFile file = Uncategorized file

categorizedFiles :: [FilePath] -> IO [Category]
categorizedFiles [] = return []
categorizedFiles (x:xs) = do
                         t <- categorizedFiles xs
                         return (categorizeFile x : t)

filterDotsInFilePaths :: [FilePath] -> [FilePath]
filterDotsInFilePaths = filter (\x -> not (x `isInfixOf` ".") && not (x `isInfixOf` ".."))

getListOfFilesRecursively :: [FilePath] -> IO [FilePath]
getListOfFilesRecursively [] = return []
getListOfFilesRecursively (x:xs) = do
                                 flag <- doesFileExist x
                                 if flag
                                 then do
                                       t <- getListOfFilesRecursively xs
                                       return (x : t)
                                 else do
                                       dirContents <- getDirectoryContents x
                                       let filteredDir = filterDotsInFilePaths dirContents
                                       let rel = map (\curr -> x ++ "/" ++ curr) filteredDir
                                       --print x
                                       --print rel
                                       f <- getListOfFilesRecursively $ rel
                                       t <- getListOfFilesRecursively xs
                                       return (force f ++ force t)

-- todo need to be fixed
-- take a look - http://stackoverflow.com/questions/3982491/find-out-whether-all-given-files-exists-in-haskell
getListOfFiles :: [FilePath] -> IO [FilePath]
getListOfFiles [] = return []
getListOfFiles (x:xs) = do
                         flag <- doesFileExist x
                         if flag
                         then do
                              t <- getListOfFiles xs
                              return (x : t)
                         else do
                              t <- getListOfFiles xs
                              return t


getListOfDirs :: [FilePath] -> IO [FilePath]
getListOfDirs [] = return []
getListOfDirs (x:xs) = do
                         flag <- doesDirectoryExist x
                         if flag
                         then do
                              t <- getListOfDirs xs
                              return (x : t)
                         else do
                              t <- getListOfDirs xs
                              return t
