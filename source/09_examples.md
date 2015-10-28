# Example Usage

## Introduction

As the major use of pytracks is to make it easier for people to use data exported by simulation models, it has the potential to be used in a variety of ways. Users can take the data and run statistical analysis on it. They can also visualize the data using various well known Python visualization modules. While working with pytracks, I focused on showing how one can visualize data with pytracks. Most of the examples which will be discussed below are centered around that.

One major module which is used by many people who use Python to visualize data is a module called matplotlib. This allows the user to visualize data similar to one would visualize data in the fairly well known program called MatLab. Pytracks is built to closely work with matplotlib to help users create visualizations more efficiently. Multiple examples were written by myself to show how one can use matplotlib with pytracks.

Note: I will not explain much into the matplotlib. The focus of the examples below is to show how easy it is to access the data. Then the usercan graph or process it using whatever utility they may desire.

##Grid Visualization

This example shows how pytracks makes it easier for a user to read data from a file and visualize a grid using matplotlib.

###Data Input

Firstly, a user needs to read in the raw data. Pytracks has the built in ability to easily read in data which follows a flexible formatting scheme:

```python
grid_wrapper = pytracks.input.GridWrapper("grid_data.out", extra_ids=[3, 4])
```

Check the appendix for the data format requirements. Pytracks allows the user to specify exactly the data they require in their script, as specified by the *extra_ids* parameter.

###Data Processing

The previous method created a **GridWrapper** class, which allows us to access the data in raw form if one desires, or generate a **Grid** class::

```python
grid = grid_wrapper.gen_grid()
```

Using the ``Grid`` class we generated, under the variable name *grid*, we can now generate data usable by matplotlib:

```python
plot_data = numpy.zeros(grid.size)
for cell in grid.cells:
   plot_data[cell.y - 1][cell.x - 1] = (cell[0] - cell[1])
```
This generates data and stores it in the *plot_data* variable for use in the visualization code.

###Visualization

The data generated earlier is used to generate a graph using matplotlib:

```python
axis.set_title("Grid Visualization")
colorbar = plot.colorbar(grid_image)
colorbar.set_ticks([-1, 0, 1])
colorbar.set_ticklabels([-1, 0, 1])
colorbar.set_label("Habitat Quality")

plot.savefig("export/grid.pdf", bbox_inches='tight', transparent=True)
plot.show()
```

###Output

Output from this example can be seen in Figure \ref{fig_example_grid}.

![Example of visualizing a grid using pytracks. \label{fig_example_grid}](source/figures/grid.pdf)

##Track Visualization

This example shows how a user can use pytracks to extract data from a grid to show how well a individual does over it's lifetime. The brown shading relates to the biomass amount as it moves through the grid. Darker means lower biomass, and lighter means higher biomass. The green and red dots refer to the start and end points  respectfully.

###Setup Functions

To create the lines which track the biomass magnitude, we need two functions which help us with that. One function creates the line using arrays of coordinates and the data, while the other creates the segments:

```python
def colorline(x, y, data, normalize=plot.Normalize(0.0, 1.0)):

    z = numpy.asarray(data)

    segments = make_segments(x, y)
    lc = LineCollection(segments, array=z, cmap=plot.get_cmap('copper'), norm=normalize)

    ax = plot.gca()
    ax.add_collection(lc)

    return lc

def make_segments(x, y):

    points = numpy.array([x, y]).T.reshape(-1, 1, 2)
    segments = numpy.concatenate([points[:-1], points[1:]], axis=1)
    return segments

```

###Data Input

As before, the user needs to read in the raw data and generate the useful classes.

```python
grid_wrapper = pytracks.input.GridWrapper("event_25/grid.out", extra_ids=[3, 4])
tracks_wrapper = pytracks.input.TrackWrapper("event_25/Event_5.out", id_column=2, x_column=5, y_column=7, extra_ids=[10, 11])

grid = grid_wrapper.gen_grid()
trackset = tracks_wrapper.gen_trackset()
```

###Grid Visualization

As done in the previous example, the grid needs to be visualized again:

```python
plot_data = numpy.zeros(grid.size)
for cell in grid.cells:
    plot_data[cell.y - 1][cell.x - 1] = (cell[0] - cell[1])
```

###Figure Setup

The user needs to initialize the figure so it can be drawn on:

```python
figure, axis = plot.subplots(figsize=(6, 7))
```

###Fetching a Sample Track

The following line fetches a random track from the ``TrackSet`` created with the data read in. We then get the only track in the set.

```python
newset = trackset.get_tracks_random(1)
track = newset[0]
```

###Drawing Start and End Points

We then need to indicate where the ``Track`` started and where it ended:

```python
area = numpy.pi * (5)**2 # dot radius of 5
plot.scatter(track.x[0]/25, track.y[0]/25, c="green", s=area, zorder=3)
plot.scatter(track.x[-1]/25, track.y[-1]/25, c="red", s=area, zorder=3)
```

###Drawing the Path

Then, we will draw the path and save the figure:

```python
path = Path(numpy.column_stack([track.x/25, track.y/25]))
verts = path.interpolated(steps=3).vertices
x, y = verts[:, 0], verts[:, 1]
data = numpy.true_divide(track.biomasses, max_biomass)
axis.add_collection(colorline(x, y, data))

axis.set_title("Lifetime - Biomass")
axis.set_xlim([0, 100])
axis.set_ylim([0, 100])

figure.subplots_adjust(bottom=0.235)
colorbar_axis = figure.add_axes([0.15, .12, .73, .05])

grid_image = axis.imshow(plot_data, interpolation='none', origin="lower", cmap=plot.get_cmap("Blues_r"), vmin=-1, vmax=1, extent=[0, 100, 0, 100], aspect="equal")
colorbar = plot.colorbar(grid_image, cax=colorbar_axis, orientation='horizontal')
colorbar.set_ticks([-1, 0, 1])
colorbar.set_ticklabels([-1, 0, 1])
colorbar.set_label("Habitat Quality")

plot.savefig("export/tracks_lifetime.pdf", bbox_inches='tight', transparent=True)
plot.show()
```

###Output

Output from this example can be seen in Figure \ref{fig_example_track}.

![Example of visualizing a grid and the biomass over time using pytracks. The start and end points of the track are shown with a green and red dot respectively. \label{fig_example_track}](source/figures/tracks_lifetime.pdf)

##Heatmap

This example looks at the data in an Eulerian point of view. Below we create a graph which shows 4 snapshots of the overall biomass distribution in specific ticks of the simulation.

###Initialization Code

As before, most of the code to initialize and prepare for processing is the same:

```python
grid_wrapper = pytracks.input.GridWrapper("HMRC_100/grid.out", extra_ids=[3, 4])
tracks_wrapper = pytracks.input.TrackWrapper("HMRC_100/HMRC_20.out", id_column=2, x_column=5, y_column=7, extra_ids=[10, 11])

grid = grid_wrapper.gen_grid()
trackset = tracks_wrapper.gen_trackset()

figure, axlist = plot.subplots(nrows=2, ncols=2, sharex="col", sharey="row", figsize=(6, 7))
```

###Initializing a Array for Data

This code creates a length 4 array which will allow us to create maps for each plot. In this code we also prepare the titles and select the specific ticks we want to look at.

```python
titles = ["Biomass - Tick ", "Biomass - Tick ", "Biomass - Tick ", "Biomass - Tick "]
plots_data = [numpy.zeros(grid.size) for _ in range(4)]
tl = len(trackset[0]) - 1
ticks = [0, int(round(tl * 0.33)), int(round(tl * 0.66)), tl]
```

###Calculations

This code calculates the biomass density for each cell and stores it in the variables we initialized earlier. We also set the titles to the tick number.

```python
for i in range(4):
    for track in trackset:
        x_coord = math.floor(track.x[ticks[i]]/100)
        y_coord = math.floor(track.y[ticks[i]]/100)
        plots_data[i][y_coord - 1][x_coord - 1] += track.biomasses[ticks[i]]
    titles[i] += str(ticks[i])
```

###Visualization Code

The below code has a line which finds the maximum biomass of every cell, to assure that the colorbar range is valid for each plot. Other than that, typical matplotlib code is below.

```python
max_biomass = int(round(numpy.amax(plots_data)))

for axis, plot_data, title in zip(axlist.flat, plots_data, titles):
    axis.set_xlim([0, 25])
    axis.set_ylim([0, 25])
    axis.set_title(title)
    cbar = axis.imshow(plot_data, interpolation='none', origin="lower", cmap=plot.get_cmap("afmhot"), vmin=0, vmax=max_biomass, extent=[0, 25, 0, 25], aspect="equal")

figure.subplots_adjust(bottom=0.235)
colorbar_axis = figure.add_axes([0.15, .12, .73, .05])

colorbar = plot.colorbar(cbar, cax=colorbar_axis, orientation="horizontal")
colorbar.set_ticks([0, max_biomass])
colorbar.set_ticklabels(["Low", "High"])
colorbar.set_label("Biomass Concentration")

plot.savefig("export/ticks_heatmap.pdf", bbox_inches='tight', transparent=True)
plot.show()
```

###Output

Output from this example can be seen in Figure \ref{fig_example_heatmap}.

![Example of visualizing the biomass density in the grid at specific ticks.\label{fig_example_heatmap}](source/figures/ticks_heatmap.pdf)
