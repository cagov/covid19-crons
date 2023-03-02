# trigger cron Job
import argparse, subprocess

# parse verbose, command name
parser = argparse.ArgumentParser()
parser.add_argument('-v', '--verbose', action='store_true')
parser.add_argument('command', nargs='?', default='CovidTestTrigger')
args = parser.parse_args()


default_run_command = 'node <JOBDIR>/run_cron.js';

job_list = {
    'covidtesttrigger': {
        'dir': './CovidTestTrigger',

    }
}

if args.command.lower() not in job_list:
    print(F'Command {args.command} not found')
    exit()

job = job_list[args.command.lower()]
if 'run_command' not in job:
    job['run_command'] = default_run_command

run_command = job['run_command'].replace('<JOBDIR>', job['dir'])

if args.verbose:
    print(F'Running {run_command}')

# call the command using subprocess as a shell command, echoing the output
subprocess.call(run_command, shell=True)
