{-# LANGUAGE OverloadedStrings, TupleSections #-}


import           Control.Applicative ((<$>))
import           Control.Exception   (bracket_)
import           Data.List           (partition)
import           Data.Monoid         ((<>))
import qualified Data.Text           as T
import qualified Data.Text.IO        as TIO
import           System.Cmd
import           System.Directory
import           System.Environment  (getArgs)
import           System.Exit         (ExitCode (ExitSuccess))

main :: IO ()
main = do
  -- let's not build really basic stuff
  let alwaysIgnore = ["Cabal", "rts", "base", "ghc-prim", "integer-gmp"]
  ignorablePackages <- (++ alwaysIgnore) . map T.pack <$> getArgs

  let ignorable x = any  (`T.isPrefixOf` x) ignorablePackages
  confs <- T.lines <$> TIO.readFile "./cabal.config"
  let useful = map T.strip .
               takeWhile (T.isPrefixOf "     ") .
               map (T.replace "constraints:" "      " ) $
               dropWhile (not . T.isPrefixOf "constraints:") confs
  TIO.putStr $ T.unlines useful

  let justPkgs' = map (T.replace "," "" . T.replace " ==" "-") useful
  createDirectoryIfMissing False "./marvin-tmp"
  let (ignored, justPkgs) = partition ignorable justPkgs'
--  print ("ignoring", ignored)

  results <- (`mapM` justPkgs) $ \pkg -> do
    print ("running with", pkg)
--    let dirname = ("./marvin-tmp/" ++ T.unpack pkg)
    -- createDirectoryIfMissing False dirname
    origSandbox <- (<> "/.cabal-sandbox") <$> getCurrentDirectory

    withCurrDir "marvin-tmp" $ do
      let c =   ("cabal unpack " ++ T.unpack pkg ++
                "&& cd " ++ T.unpack pkg ++
                "&& cp -r " ++ origSandbox ++  " . " ++
                "&& cabal install --only-dependencies --enable-tests " ++
                "&& cabal configure --enable-tests" ++
                "&& cabal test")
      print ("running", c)
      (pkg,) <$> system c
  let (success,failures) = partition ((==ExitSuccess) . snd) results
  putStrLn "Ignored:"
  TIO.putStrLn $ T.unlines $ filter ignorable justPkgs'
  putStrLn "Successes:"
  TIO.putStr $ T.unlines $ map fst success
  putStrLn ""
  putStrLn "Failures"
  TIO.putStr $ T.unlines $ map fst failures



withCurrDir x f = do
  orig <- getCurrentDirectory
  bracket_ (setCurrentDirectory x) (setCurrentDirectory orig) f
