import pandas as pd
from sqlalchemy import create_engine
import os
import argparse
import sys

def get_seqbox_export(query,outfile):
       df = pd.read_sql(query,con)
       # print(df)
       df.to_excel(outfile,index=False)

todolist_query = """
       select sample.sample_identifier, sample.day_received, sample.month_received, sample.year_received, pr.pcr_result as qech_pcr_result, pr.ct as original_ct, project_name, e.extraction_identifier, DATE(e.date_extracted) as date_extracted, ccp.pcr_identifier, DATE(ccp.date_pcred) as date_covid_confirmatory_pcred,
       ccp.ct as covid_confirmation_pcr_ct, tp.pcr_identifier as tiling_pcr_identifier, DATE(tp.date_pcred) as date_tiling_pcrer, rsb.name as read_set_batch_name, r.readset_identifier, acr.pct_covered_bases
       from sample
       left join sample_source ss on sample.sample_source_id = ss.id
       left join sample_source_project ssp on ss.id = ssp.sample_source_id
       left join project on ssp.project_id = project.id
       left join pcr_result pr on sample.id = pr.sample_id
       left join extraction e on sample.id = e.sample_id
       left join covid_confirmatory_pcr ccp on e.id = ccp.extraction_id
       left join raw_sequencing rs on e.id = rs.extraction_id
       left join tiling_pcr tp on rs.tiling_pcr_id = tp.id
       left join raw_sequencing_batch rsb on rs.raw_sequencing_batch_id = rsb.id
       left join read_set r on rs.id = r.raw_sequencing_id
       left join artic_covid_result acr on r.id = acr.readset_id
       where species = 'SARS-CoV-2'
       and pr.pcr_result like 'Positive%%'
       and (project_name = any(array['ISARIC', 'COCOA', 'COCOSU', 'MARVELS']))
       order by sample.year_received desc, sample.month_received desc, sample.day_received desc;
       """
 
sequence_run_info_query = """
       select distinct on(sample_identifier) readset_identifier, sample_identifier, sample_source_identifier, original_ct, confirmatory_ct, pct_covered_bases, project_name, barcode, name, protocol, lineage, scorpio_call, year_received, month_received, day_received from
           (select readset_identifier, sample_identifier, sample_source_identifier, pr.ct as original_ct, ccp.ct as confirmatory_ct, pct_covered_bases, project_name, barcode, rsb.name, tiling_pcr.protocol, lineage, scorpio_call, year_received, month_received, day_received
               from read_set
               left join read_set_nanopore on read_set.id = read_set_nanopore.readset_id
               left join artic_covid_result on read_set.id = artic_covid_result.readset_id
               left join raw_sequencing rs on read_set.raw_sequencing_id = rs.id
               left join pangolin_result on artic_covid_result.id = pangolin_result.artic_covid_result_id
                   and pangolin_result.pangolearn_version = (select max(pangolearn_version) from pangolin_result where artic_covid_result.id = pangolin_result.artic_covid_result_id)
               left join tiling_pcr on rs.tiling_pcr_id = tiling_pcr.id
               left join raw_sequencing_batch rsb on rs.raw_sequencing_batch_id = rsb.id
               left join extraction e on rs.extraction_id = e.id
               left join sample s on e.sample_id = s.id
               left join sample_source ss on s.sample_source_id = ss.id
               left join sample_source_project ssp on ss.id = ssp.sample_source_id
               left join project p on ssp.project_id = p.id
               left join pcr_result pr on s.id = pr.sample_id
               left join covid_confirmatory_pcr ccp on e.id = ccp.extraction_id
               where not rsb.name = any(array['20210623_1513_MN33881_FAO36636_d6fbf869', '20210628_1538_MN33881_FAO36636_219737d0', '20210818_1510_MN34547_FAQ69577_004054cc'])
               and (tiling_pcr.protocol = any(array['ARTIC v3', 'UNZA Sanger', 'UNZA']) or tiling_pcr.protocol is Null)
               and (project_name = any(array['ISARIC', 'COCOA', 'COCOSU', 'MARVELS']))
               and sample_identifier != any(array['Neg ex', 'Neg_ex', 'Neg_ex', 'Neg_extract'])
           ) as foo
       order by sample_identifier, pct_covered_bases desc NULLS LAST
       """

def run_command(args):
       if args.command == "get_todolist":
              get_seqbox_export(todolist_query,args.filename)
       elif args.command == "get_seq_run_info":
              get_seqbox_export(sequence_run_info_query,args.filename)

def main():
       parser = argparse.ArgumentParser(prog='query_db')
       subparsers = parser.add_subparsers(title='[sub-commands]', dest='command')
       get_todolist_parser = subparsers.add_parser('get_todolist',help='Take a filename as a parameter')
       get_todolist_parser.add_argument('-i',dest='filename',help='Filename of query output',
       required=True)

       get_seq_run_info_parser = subparsers.add_parser('get_seq_run_info',help='Getting sequencing info from seqbox')
       get_seq_run_info_parser.add_argument('-i',dest='filename',help='Return a file with latest sequencing info from the database',
       required=True)

       # print the help if no arguments passed
       if len(sys.argv) == 1:
           parser.print_help(sys.stderr)
           sys.exit(1)
       args = parser.parse_args()
       run_command(args)

if __name__ == '__main__':
       # Createe engine instance
       eng = create_engine(f"{os.environ.get('DATABASE_URL')}",pool_recycle=3600)
 
       # Connect to postgresql server
       con = eng.connect()
       main()
       con.close()
