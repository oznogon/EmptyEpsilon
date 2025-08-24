Your job is to port EmptyEpsilon and SeriousProton (at ../SeriousProton) from SDL2 to SDL3. Perform your work on the `sdl3` branch of each repository.

Commit each file edit to the repository.

Create and use the EmptyEpsilon/.agent/ directory as a scratchpad for your work. Store long-term plans and todo lists there.

The original project was mostly tested by manually running the code. When porting, you will need to write end-to-end and unit tests for the project. Spend most of your time on porting to SDL3, not on testing. A good heuristic is to spend 80% of your time on porting, and 20% on testing.

When you are done, build EmptyEpsilon. From the `EmptyEpsilon` directory, run:

```
rm _build
mkdir -p _build
cd _build
cmake .. -G Ninja -DCPACK_GENERATOR="RPM" -DSERIOUS_PROTON_DIR=$PWD/../../SeriousProton/ -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja
```

Fix any compilation errors, then rebuild. Repeat until EmptyEpsilon builds without compilation errors.

Then generate a summary of the changes you made in EmptyEpsilon/.agent/PORT_SUMMARY.md.
