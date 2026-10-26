"Loads Buoy v8, Aconcagua v11 and this checkout of Chalten (Development group, which includes
 PersonalLines-Rating and its tests) into the running image from local clones, then saves it.
 Paths are injected by run_pharo.sh through the CHALTEN_DEPS_DIR and CHALTEN_SOURCE_DIR variables."
| depsDir sourceDir |
depsDir := OSEnvironment current at: 'CHALTEN_DEPS_DIR'.
sourceDir := OSEnvironment current at: 'CHALTEN_SOURCE_DIR'.
Metacello new
  baseline: 'Buoy';
  repository: 'gitlocal://', depsDir, '/Buoy/source';
  load: #('Deployment' 'Dependent-SUnit-Extensions' 'Tools').
Metacello new
  baseline: 'Aconcagua';
  repository: 'gitlocal://', depsDir, '/Aconcagua/source';
  onConflictUseLoaded;
  load: #('Deployment' 'Tools').
Metacello new
  baseline: 'Chalten';
  repository: 'tonel://', sourceDir;
  onConflictUseLoaded;
  load: 'Development'.
Transcript show: 'CHALTEN LOADED'; cr.
Smalltalk snapshot: true andQuit: true.
