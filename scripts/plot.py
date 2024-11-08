import matplotlib.pyplot as plt
import numpy as np
import sys
import pandas as pd
import seaborn as sns
import os

_LINE_FORMATS = ['x-', 'o--', '.-.', '+:']
_COLORS = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf']

def plot_inc_nodes(dir = './'):
    data = pd.read_csv(f'{dir}output_increase_nodes_detailed.txt', sep=r'\s*,\s*', engine='python').drop(columns=['build'])

    fig, ax = plt.subplots(1,1,figsize=(10,7),layout='constrained')

    data['Setting'] = data[['threads']].apply(lambda x: f'Threads {x[0]:.0e}', axis = 1)
    nr_hues = len(data['Setting'].unique())
    sns.lineplot(data, x='nodes', y='graph_creation', hue='Setting',
                    palette=_COLORS[:nr_hues], style='Setting', markers=True)

    ax.tick_params(axis='both', which='both', labelsize=15)
    ax.set_ylabel('Graph Creation Time (s)', fontweight='bold', fontsize = 18)
    ax.set_xlabel('Graph Nodes', fontweight='bold',fontsize = 18)

    ax.grid()
    ax.legend(prop={'size': 18, 'weight':'bold'})
    fig.savefig(f'{dir}output_increase_nodes_detailed.png')

def plot_inc_git(dir = './'):
    data = pd.concat([pd.read_csv(f'{dir}output_kernels_increase_it_detailed.txt',
                                  sep=r'\s*,\s*', engine='python').drop(columns=['build']),
                      pd.read_csv(f'{dir}output_graph_increase_it_detailed.txt',
                                  sep=r'\s*,\s*', engine='python').drop(columns=['build'])])

    data['Setting'] = data[['mode','threads']].apply(lambda x: f'{"Graph" if x[0] == 1 else "Baseline"}: Threads {x[1]:.0e}', axis = 1)
    nr_hues = len(data['Setting'].unique())
    fig, ax = plt.subplots(1,1,figsize=(10,7),layout='constrained')
    sns.lineplot(data, errorbar='sd', x='launches', y='exec', hue='Setting',
                    palette=_COLORS[:nr_hues], style='Setting', markers=True)

    ax.tick_params(axis='both', which='both', labelsize=15)
    ax.set_ylabel('Execution Time (s)', fontweight='bold', fontsize = 18)
    ax.set_xlabel('Nr of Executed Iteration batches', fontweight='bold',fontsize = 18)

    ax.grid()
    ax.legend(prop={'size': 18, 'weight':'bold'})
    fig.savefig(f'{dir}output_increase_it_detailed.png')

def plot_graph_ratio(dir='./'):
    data = pd.read_csv(f'{dir}output_increase_nodes_standard.txt',
                       sep=r'\s*,\s*', engine='python').drop(columns=['build'])

    time_min = ['threads','cuda_diff']
    groupby = ['threads', 'launches']
    time = 'cuda_diff'
    nodes = 'nodes'

    mins = data.groupby(by=groupby, as_index=False).mean().groupby(by=[groupby[0]]).min()[time]
    data[time] = data[time_min].apply(lambda x: x[1]/mins[x[0]].min(), axis = 1)

    data['Setting'] = data[['threads']].apply(lambda x: f'Threads {x["threads"]:.0e}', axis = 1)

    col = data.columns
    data = data.loc[data[nodes] < 2000, col]
    fig, ax = plt.subplots(1,1,figsize=(10,7),layout='constrained')
    nr_hues = len(data['Setting'].unique())
    sns.lineplot(data, errorbar='sd', x=nodes, y=time, hue='Setting',
                 palette=_COLORS[:nr_hues], style='Setting', markers=True)

    ax.tick_params(axis='both', which='both', labelsize=15)
    ax.set_ylabel('Ratio', fontweight='bold', fontsize = 18)
    ax.set_xlabel('Graph Nodes', fontweight='bold',fontsize = 18)

    ax.grid()
    ax.legend(prop={'size': 18, 'weight':'bold'})
    fig.savefig(f'{dir}output_increase_nodes_standard.png')

def plot_speedup(dir):
    data = { 'k':pd.read_csv(f'{dir}output_kernels_increase_it_standard.txt',
                             sep=r'\s*,\s*', engine='python').drop(columns=['build']),
             'g':pd.read_csv(f'{dir}output_graph_increase_it_standard.txt',
                             sep=r'\s*,\s*', engine='python').drop(columns=['build'])
            }
    groupby = ['threads','launches']
    time = 'cuda_diff'

    df = data['g'].groupby(by=groupby, as_index=False).mean()
    g_var = data['g'].groupby(by=groupby, as_index=False).var()
    k_mean = data['k'].groupby(by=groupby, as_index=False).mean()
    k_var = data['k'].groupby(by=groupby, as_index=False).var()

    df['Speed-up'] = k_mean[time]/df[time]

    df['Speed-up Error'] = np.sqrt(df['Speed-up'] * (
                                (k_var[time]/np.power(k_mean[time],2)) +
                                (g_var[time]/np.power(df[time],2))))

    df['Speed-up Error low'] = df['Speed-up'] - df['Speed-up Error']
    df['Speed-up Error high'] = df['Speed-up'] + df['Speed-up Error']

    fig, ax = plt.subplots(1,1,figsize=(10,7),layout='constrained')

    df['Setting'] = df[['threads']].apply(lambda x: f'Threads {x["threads"]:.0e}', axis = 1)

    nr_hues = len(df['Setting'].unique())
    ax = sns.lineplot(df, x='launches', y='Speed-up', hue='Setting',
                      palette=_COLORS[:nr_hues], style='Setting', markers=True)

    cnt = 0
    for i in df['threads'].unique():
        d = df.loc[df['threads']==i]
        ax.fill_between(d['launches'], d['Speed-up Error low'], d['Speed-up Error high'],
                        color=_COLORS[cnt], alpha = 0.2)
        cnt +=1

    ax.tick_params(axis='both', which='both', labelsize=15)
    ax.set_ylabel('Speed-up', fontweight='bold', fontsize = 18)
    ax.set_xlabel('Nr of Executed Iteration batches', fontweight='bold',fontsize = 18)

    ax.grid()
    ax.legend(prop={'size': 18, 'weight':'bold'})
    fig.savefig(f'{dir}output_increase_it_standard.png')

def plot_mem(dir):
    datafile = f'{dir}output_mem.txt'
    if not os.path.isfile(datafile):
        print("No memory data, not plotting.")
        return
    data = pd.read_csv(datafile,
                        sep=r'\s*,\s*', engine='python').drop(columns=['build'])

    if not 'Memory (MiB)' in data.columns:
        data['Memory (MiB)'] = data['Memory (B)']/1024/1024

    data['Setting'] = data[['threads']].apply(lambda x: f'Threads {x["threads"]:.0e}', axis = 1)
    nr_hues = len(data['Setting'].unique())
    fig, ax = plt.subplots(1,1,figsize=(10,7),layout='constrained')
    sns.lineplot(data, x = 'nodes', y='Memory (MiB)', hue='Setting',
                 palette=_COLORS[:nr_hues],
                 style='Setting', markers=True)

    ax.tick_params(axis='both', which='both', labelsize=15)
    ax.set_ylabel('Memory Usage (MiB)', fontweight='bold', fontsize = 18)
    ax.set_xlabel('Graph Nodes', fontweight='bold',fontsize = 18)

    ax.grid()
    ax.legend(prop={'size': 18, 'weight':'bold'})
    fig.savefig(f'{dir}output_mem.png')

if __name__ == '__main__':
    dir = './'
    if len(sys.argv[1]) > 1:
        dir = sys.argv[1]

    if dir[-1] != '/':
        dir += '/'

    plot_inc_nodes(dir)
    plot_inc_git(dir)
    plot_graph_ratio(dir)
    plot_speedup(dir)
    plot_mem(dir)
    plt.show()


