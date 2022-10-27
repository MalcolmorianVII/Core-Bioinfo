import os
import json
import pprint
import requests
from datetime import datetime


def process_samples(sample_information, studycode_lookup):
    print(','.join(['sample_source_identifier', 'sample_source_type', 'township', 'city', 'country', 'latitude', 'longitude', 'projects', 'group_name', 'institution', 'sample_identifier', 'species', 'sample_type', 'day_collected', 'month_collected', 'year_collected', 'day_received', 'month_received', 'year_received', 'date_pcred', 'pcr_identifier', 'pcr_result', 'ct', 'pcred_institution', 'assay_name']))
    pcr_identifier_lookup = {}
    for sample in sample_information:
        # some of the samples have strange study ids
        try:
            study = studycode_lookup[sample['lab_id'][0:3]][0]
            group = studycode_lookup[sample['lab_id'][0:3]][1]
        except KeyError:
            # print(f"{sample['lab_id'][0:3]} not in studycode_lookup")
            continue
        # if result isn't one of these, then ignore it
        #print(sample)
        if 'result' not in sample:
            continue
        if sample['result'] not in {'Negative', 'Positive', 'Positive - Followup', 'Negative - Followup'}:
            continue
        if 'CT_Cov19' not in sample:
            sample['CT_Cov19'] = ''
        if sample['CT_Cov19'] in ['Not done', 'N/A', 'na']:
            sample['CT_Cov19'] = ''
        sample['CT_Cov19'] = sample['CT_Cov19'].strip()
        # print(sample)
        # get year, month, day of receipt
        year, month, day = sample['date_sample_received'].split('-')
        # convert day resulted to d-m-y
        date_resulted = datetime.strptime(sample['date_sample_resulted'], '%Y-%m-%d').date()
        date_resulted = date_resulted.strftime('%d/%m/%Y')
        #calc pcr identifier
        pcr_identifier = ''
        if sample['lab_id'] in pcr_identifier_lookup:
            pass
        else:
            pcr_identifier_lookup[sample['lab_id']] = {}
        if date_resulted in pcr_identifier_lookup[sample['lab_id']]:
            pcr_identifier_lookup[sample['lab_id']][date_resulted] += 1
        else:
            pcr_identifier_lookup[sample['lab_id']][date_resulted] = 1

        print(','.join([sample['pid'], 'patient', '', '', '', '', '', study, group, 'MLW', sample['lab_id'], 'SARS-CoV-2', '', '', '', '', day, month, year, date_resulted, str(pcr_identifier_lookup[sample['lab_id']][date_resulted]), sample['result'], sample['CT_Cov19'], 'MLW', 'SARS-CoV2-CDC-N1']))


def get_data(url, headers):
    
    payload = {}
    response = requests.get(url, data=json.dumps(payload), headers=headers)
    
    
    clean_response_text = response.text.lstrip('<br />\n<b>Warning</b>:  Undefined array key 0 in <b>/var/www/html/api/v1/R/classes/Results/Covid.class.php</b> on line <b>43</b><br />\n')
    # pprint.pprint(clean_response_text)
    return clean_response_text


def main():
    studycode_lookup = {'CQD':['COCOSU', 'ViralImmunology'], 'CQE':['COCOSU', 'ViralImmunology'], 'CMT':['ISARIC', 'Core'], 'CPH':['COCOA', 'Core'], 'CPG':['MLW_staff_testing', 'Core'], 'CRP':['Peri-COVID', 'PaediatricsFreyne'], 'CRN':['Peri-COVID', 'PaediatricsFreyne'], 'CQN':['CLIC', 'MucosalImmunology'], 'CRR':['Peri-COVID', 'PaediatricsFreyne'], 'CRQ':['Peri-COVID', 'PaediatricsFreyne'], 'CRJ':['IMPAC', 'ParasitesMoxon'], 'CMU':['DHO_COVID_support', 'Core'], 'CSJ':['MARVELS', 'StephenGordonGroup']}
    # password = os.environ['COVIDDATAPWD']
    url = 'http://10.137.16.22:8080/v1/dataset?route=covid'
    headers = {'Authorization': 'Token 8112376b290b1314ec15dff633aac7c65a93ce1e', 'content-type': 'application/json'}

    # response = requests.get(url_for_api)
    #response = requests.get(f"http://10.137.16.21/api/v1/?route=get-c19-data&username=pashton&password={password}")
    #print(clean_response_text)
    # sample_information is a string of json
    clean_response_text = get_data(url, headers)
    sample_information = json.loads(clean_response_text)
    # pprint.pprint(sample_information)
    # sample_information = json.load(open('/Users/flashton/Desktop/tmp.json'))
    # print(sample_information)
    process_samples(sample_information, studycode_lookup)


if __name__ == '__main__':
    main()
