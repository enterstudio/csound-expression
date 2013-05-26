module Csound.Render(
    render    
) where

import qualified Data.IntMap as IM

import Csound.Exp
import Csound.Exp.Options
import Csound.Render.Pretty
import Csound.Render.Instr
import Csound.Render.Options
import Csound.Render.Channel

import Csound.Exp.Tuple(Out)
import Csound.Exp.Mix
import Csound.Exp.GE
import Csound.Exp.EventList

render :: (Out a, CsdSco f) => CsdOptions -> f (Mix a) -> IO String
render opt a = fmap (show . renderHistory (nchnls a) (csdEventListDur events) opt) 
    $ execGE (saveMasterInstr events) opt
    where events = toCsdEventList a

saveMasterInstr :: CsdEventList (Mix a) -> GE ()
saveMasterInstr = undefined

renderHistory :: Int -> Double -> CsdOptions -> History -> Doc
renderHistory numOfChnls totalDur options history = ppCsdFile 
    -- flags
    (renderFlags options) 
    -- instr 0
    (renderInstr0 numOfChnls (midis history) options)
    -- orchestra
    (renderOrc $ instrs history)
    -- scores
    (renderSco $ scos history)
    -- strings
    (ppMapTable ppStrset $ strIndex history)
    -- ftables
    (ppTotalDur totalDur $$ (ppMapTable ppTabDef $ tabIndex history))    

    
renderSco :: Scos -> Doc
renderSco x = vcat $ fmap ppAlwayson $ alwaysOnInstrs x

renderOrc :: Instrs -> Doc
renderOrc x = (vcatMap renderSource $ instrSources x) $$ (vcatMap renderMixer $ instrMixers x)
    where getMixerNotes instrId = (fmap renderNotes $ mixerNotes x) IM.! (instrIdCeil instrId)
          
          renderSource = uncurry renderInstr    
          renderMixer  (instrId, expr) = ppInstr instrId $
               ppFreeChnStmt
            $$ getMixerNotes instrId
            $$ renderInstrBody expr

renderNotes :: [(InstrId, Note)] -> Doc
renderNotes = undefined


