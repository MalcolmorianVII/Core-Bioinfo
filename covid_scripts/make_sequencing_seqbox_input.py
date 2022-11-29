import os
import sys
import csv
import sys
import pprint
import dateutil.parser
from datetime import datetime


def read_in_seqtracker(seqtracker_handle):
    with open(seqtracker_handle, encoding='utf-8-sig') as fi:
        seqtracker = csv.DictReader(fi, delimiter=',')
        # i think the generator doesnt work when the file is closed?
        # so need to do this.
        seqtracker = [x for x in seqtracker]
    # print(seqtracker)
    return seqtracker

batch_dir = sys.argv[1]

def write_raw_seq_batch(batch_name, raw_seq_batch_outfile):
    sequencing_date = batch_name.split('_')[0]
    sequencing_date = f'{sequencing_date[6:8]}/{sequencing_date[4:6]}/{sequencing_date[0:4]}'
    raw_seq_batch_outfile.write(f'{batch_dir},{batch_name},{sequencing_date},nanopore,minion_mk1b,mlw_minion_mk1b_a,sqk-lsk109,MLW,R9.4.1\n')


def write_readset_batch(batch_name, readset_batch_outfile):
    readset_batch_outfile.write(f'{batch_name},{batch_name},{batch_dir},guppy v5 sup\n')


def get_group_name(sample_id):
    studycode_lookup = {'CQD':['COCOSU', 'ViralImmunology'], 'CQE':['COCOSU', 'ViralImmunology'], 'CMT':['ISARIC', 'Core'], 'CPH':['COCOA', 'Core'], 'CPG':['MLW_staff_testing', 'Core'], 'CRP':['Peri-COVID', 'PaediatricsFreyne'], 'CRN':['Peri-COVID', 'PaediatricsFreyne'], 'CQN':['CLIC', 'MucosalImmunology'], 'CRR':['Peri-COVID', 'PaediatricsFreyne'], 'CRQ':['Peri-COVID', 'PaediatricsFreyne'], 'CRJ':['IMPAC', 'ParasitesMoxon'], 'CMU':['DHO_COVID_support', 'Core'], 'CSJ':['MARVELS', 'StephenGordonGroup'], 'CSP':['MARVELS', 'StephenGordonGroup'], 'Neg': ['Core', 'Core'], 'NEG': ['Core', 'Core'], 'ERS':['ES_COVID', 'VirologyBarnes'], 'BGT':['EQA', 'Core']}
    try:
        if sample_id[0:5] == 'MEIRU':
            return 'MEIRU_COVID'
        else:
            group_name = studycode_lookup[sample_id[0:3]][1]
            return group_name
    except KeyError:
        print(f"{sample_id[0:3]} not in studycode_lookup")
        sys.exit()


def set_barcode(barcode):
    if len(barcode) == 1:
        barcode = '0' + barcode
    assert len(barcode) == 2
    barcode = 'barcode' + barcode
    return barcode


def write_sequencing(seqtracker, batch_name, sequencing_outfile):
    for sample in seqtracker:
        if sample['Barcode'] == '':
            continue
        # print(sample)
        if sample['confirmation Ct'] == 'neg':
            sample['confirmation Ct'] = ''
        # print(sample)
        group_name = get_group_name(sample["Sample ID"])
        extraction_date = dateutil.parser.parse(sample['extraction date'], dayfirst = True)
        # extraction_date = datetime.strptime(sample['extraction date'], '%d-%b-%y')
        extraction_date = extraction_date.strftime('%d/%m/%Y')
        covid_confirmatory_pcr_date = dateutil.parser.parse(sample['covid confirmation pcr date'], dayfirst = True)
        # covid_confirmatory_pcr_date = datetime.strptime(sample['covid confirmation pcr date'], '%d-%b-%y')
        covid_confirmatory_pcr_date = covid_confirmatory_pcr_date.strftime('%d/%m/%Y')
        tiling_pcr_date = dateutil.parser.parse(sample['tiling pcr date'], dayfirst=True)
        tiling_pcr_date = tiling_pcr_date.strftime('%d/%m/%Y')

        sample['Barcode'] = set_barcode(sample['Barcode'])

        sequencing_outfile.write(f'{sample["Sample ID"]},{group_name},MLW,{extraction_date},{sample["extraction_identifier"]},{sample["extraction method"]},,MLW,RNA,whole sample,{covid_confirmatory_pcr_date},{sample["covid_confirmatory_pcr_identifier"]},{sample["covid confirmatory pcr protocol"]},{sample["confirmation Ct"]},{tiling_pcr_date},{sample["tiling_pcr_identifier"]},{sample["tiling pcr protocol"]},,{sample["Barcode"]},mlw-gpu-1,{batch_name}\n')


def assign_identifiers(seqtracker):
    extraction_identifier_lookup = {}
    confirmatory_pcr_identifier_lookup = {}
    tiling_pcr_identifier_lookup = {}
    for sample in seqtracker:
        if sample["Sample ID"] in extraction_identifier_lookup:
            pass
        else:
            extraction_identifier_lookup[sample["Sample ID"]] = {}
        
        if sample['extraction date'] in extraction_identifier_lookup[sample["Sample ID"]]:
            extraction_identifier_lookup[sample["Sample ID"]][sample['extraction date']] += 1
            sample['extraction_identifier'] = extraction_identifier_lookup[sample["Sample ID"]][sample['extraction date']]
        else:
            extraction_identifier_lookup[sample["Sample ID"]][sample['extraction date']] = 1
            sample['extraction_identifier'] = 1


        if sample["Sample ID"] in confirmatory_pcr_identifier_lookup:
            pass
        else:
            confirmatory_pcr_identifier_lookup[sample["Sample ID"]] = {}
        
        if sample['covid confirmation pcr date'] in confirmatory_pcr_identifier_lookup[sample["Sample ID"]]:
            confirmatory_pcr_identifier_lookup[sample["Sample ID"]][sample['covid confirmation pcr date']] += 1
            sample['covid_confirmatory_pcr_identifier'] = confirmatory_pcr_identifier_lookup[sample["Sample ID"]][sample['covid confirmation pcr date']]
        else:
            confirmatory_pcr_identifier_lookup[sample["Sample ID"]][sample['covid confirmation pcr date']] = 1
            sample['covid_confirmatory_pcr_identifier'] = 1


        if sample["Sample ID"] in tiling_pcr_identifier_lookup:
            pass
        else:
            tiling_pcr_identifier_lookup[sample["Sample ID"]] = {}
        
        if sample['tiling pcr date'] in tiling_pcr_identifier_lookup[sample["Sample ID"]]:
            tiling_pcr_identifier_lookup[sample["Sample ID"]][sample['tiling pcr date']] += 1
            sample['tiling_pcr_identifier'] = tiling_pcr_identifier_lookup[sample["Sample ID"]][sample['tiling pcr date']]
        else:
            tiling_pcr_identifier_lookup[sample["Sample ID"]][sample['tiling pcr date']] = 1
            sample['tiling_pcr_identifier'] = 1



def main():
    '''
    1. read in:
        a. seqtracker
            i. filter out only ones with barcode.
            ii. some seqtrackers will have samples which had a confirmatory ct
                that was too low
        b. batch name
    2. need to write out:
        a. raw_sequencing_batches
            batch_directory
            batch_name
            date_run
            sequencing_type
            instrument_model
            instrument_name
            library_prep_method
            sequencing_centre
            flowcell_type
        b. read_set_batches
            raw_sequencing_batch_name
            readset_batch_name
            readset_batch_dir
            basecaller
        c. sequencing.csv with:
            sample_identifier
            group_name
            institution
            date_extracted
            extraction_identifier
            extraction_machine
            extraction_kit
            extraction_processing_institution
            what_was_extracted
            extraction_from
            date_covid_confirmatory_pcred
            covid_confirmatory_pcr_identifier
            covid_confirmatory_pcr_protocol
            covid_confirmatory_pcr_ct
            date_tiling_pcred
            tiling_pcr_identifier
            tiling_pcr_protocol
            number_of_cycles
            barcode
            data_storage_device
            readset_batch_name
    '''
    # seqtracker_handle = ''
    # batch_names = ['', '20211209_1200_MN34547_FAQ93072_fb74f355']
    batch_seqtracker = {os.environ.get('BATCH'):os.environ.get('SEQTRACKER')} # Seqtracker should point to a csv

    outdir = os.environ.get('FAST_INFILES')
    raw_seq_batch_outhandle = f'{outdir}/raw_sequencing_batches.csv'
    readset_batch_outhandle = f'{outdir}/readset_batches.csv'
    sequencing_outhandle = f'{outdir}/sequencing.csv'

    raw_seq_batch_outfile = open(raw_seq_batch_outhandle, 'w')
    raw_seq_batch_outfile.write('batch_directory,batch_name,date_run,sequencing_type,instrument_model,instrument_name,library_prep_method,sequencing_centre,flowcell_type\n')

    readset_batch_outfile = open(readset_batch_outhandle, 'w')
    readset_batch_outfile.write('raw_sequencing_batch_name,readset_batch_name,readset_batch_dir,basecaller\n')
    sequencing_outfile = open(sequencing_outhandle, 'w')
    sequencing_outfile.write('sample_identifier,group_name,institution,date_extracted,extraction_identifier,extraction_machine,extraction_kit,extraction_processing_institution,what_was_extracted,extraction_from,date_covid_confirmatory_pcred,covid_confirmatory_pcr_identifier,covid_confirmatory_pcr_protocol,covid_confirmatory_pcr_ct,date_tiling_pcred,tiling_pcr_identifier,tiling_pcr_protocol,number_of_cycles,barcode,data_storage_device,readset_batch_name\n')
    for batch_name in batch_seqtracker:
        seqtracker = read_in_seqtracker(batch_seqtracker[batch_name])
        # pprint.pprint(seqtracker)
        assign_identifiers(seqtracker)
        write_raw_seq_batch(batch_name, raw_seq_batch_outfile)
        write_readset_batch(batch_name, readset_batch_outfile)
        write_sequencing(seqtracker, batch_name, sequencing_outfile)
    raw_seq_batch_outfile.close()
    readset_batch_outfile.close()
    # sequencing_outfile.close()

if __name__ == '__main__':
    main()











