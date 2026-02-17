package eu.daid.emptyepsilon

import org.libsdl.app.SDLActivity

class EmptyEpsilonActivity : SDLActivity() {
    override fun getLibraries(): Array<String> {
        return arrayOf(
            "SDL2",
            "EmptyEpsilon"
        )
    }
}
