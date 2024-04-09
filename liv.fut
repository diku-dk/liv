import "lib/github.com/diku-dk/lys/lys"
import "genlife"
import "conway"
import "quad"
import "quad2"
import "rule101"

-- Quick and dirty hashing to mix in something that looks like entropy.
-- From http://stackoverflow.com/a/12996028
local
def hash (x: i32): i32 =
  let x = u32.i32 x
  let x = ((x >> 16) ^ x) * 0x45d9f3b
  let x = ((x >> 16) ^ x) * 0x45d9f3b
  let x = ((x >> 16) ^ x)
  in i32.u32 x

def randcell (x: i64) : bool =
  bool.i32(hash (i32.i64 x) & 1)

module conway = conway_fading
module quad = quad_fading

type text_content = i64
module lys: lys with text_content = text_content = {
  type~ state = {seed: u32,
                 world:
                   #conway [][]conway.cell
                   | #quad [][]quad.cell
                   | #rule101 [][]rule101.cell}
  def grab_mouse = false

  def init (seed: u32) (h: i64) (w: i64): state =
    {seed,
     world=
     match seed % 3
     case 0 ->
       #conway (conway.init (tabulate_2d h w (\i j -> randcell((i^j^i64.u32 seed)))))
     case 1 ->
       #quad (quad.init (tabulate_2d h w (\i j -> randcell((i^j^i64.u32 seed)))))
     case _ ->
       #rule101 (rule101.init (tabulate_2d h w (\i j -> randcell((i^j^i64.u32 seed)))))
    }

  def resize (h: i64) (w: i64) (s: state) : state =
    s with world =
    match s.world
    case #conway _ ->
      #conway (conway.init (tabulate_2d h w (\i j -> randcell(i^j^i64.u32 s.seed))))
    case #quad _ ->
      #quad (quad.init (tabulate_2d h w (\i j -> randcell(i^j^i64.u32 s.seed))))
    case #rule101 _ ->
      #rule101 (rule101.init (tabulate_2d h w (\i j -> randcell(i^j^i64.u32 s.seed))))

  def keydown (_key: i32) (s: state) = s

  def keyup (_key: i32) (s: state) = s

  def event (e: event) (s: state) =
    match e
    case #step _td ->
      s with world = (match s.world
                      case #conway world -> #conway (conway.step world)
                      case #quad world -> #quad (quad.step world)
                      case #rule101 world -> #rule101 (rule101.step world))
    case _ -> s

  def render (s: state) =
    match s.world
    case #conway world -> conway.render world
    case #quad world -> quad.render world
    case #rule101 world -> rule101.render world

  type text_content = text_content

  def text_format () =
    "Ruleset: %[conway|quad|101]"

  def text_content (_render_duration: f32) (s: state): text_content =
    match s.world case #conway _ -> 0
                  case #quad _ -> 1
                  case #rule101 _ -> 2

  def text_colour = const argb.yellow }
