<?php

namespace App\Services;

use App\Models\DictionaryCategory;
use PhpOffice\PhpSpreadsheet\Cell\DataValidation;
use PhpOffice\PhpSpreadsheet\NamedRange;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

/**
 * Builds the single-workbook Excel (.xlsx) template admins download to fill
 * in vocabulary and sentence examples in one file, instead of two separate
 * CSV downloads. Category names are offered as a dropdown so operators
 * never have to guess spelling, and sample rows show the expected format.
 */
class DictionaryExcelTemplateService
{
    public function build(): Spreadsheet
    {
        $spreadsheet = new Spreadsheet;
        $spreadsheet->removeSheetByIndex(0);

        $categories = DictionaryCategory::query()->active()->orderBy('name')->pluck('name')->all();
        if ($categories === []) {
            $categories = ['Verba', 'Nomina', 'Sapaan'];
        }

        $this->buildCategorySheet($spreadsheet, $categories);
        $this->buildVocabularySheet($spreadsheet, $categories);
        $this->buildSentenceSheet($spreadsheet);

        $spreadsheet->setActiveSheetIndex(1);

        return $spreadsheet;
    }

    public function write(Spreadsheet $spreadsheet): string
    {
        $writer = new Xlsx($spreadsheet);
        ob_start();
        $writer->save('php://output');

        return ob_get_clean() ?: '';
    }

    private function buildCategorySheet(Spreadsheet $spreadsheet, array $categories): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle('Daftar Kategori');
        foreach ($categories as $index => $category) {
            $sheet->setCellValue('A'.($index + 1), $category);
        }
        $sheet->setSheetState(Worksheet::SHEETSTATE_HIDDEN);
        $spreadsheet->addNamedRange(new NamedRange('KategoriKamus', $sheet, '$A$1:$A$'.count($categories)));
    }

    private function buildVocabularySheet(Spreadsheet $spreadsheet, array $categories): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle(config('dictionary.xlsx_sheets.vocabulary'));

        $headers = config('dictionary.xlsx_headers.vocabulary');
        $this->writeHeaderRow($sheet, $headers);

        $samples = [
            ['Makan', 'Monga', 'Eat', $categories[0] ?? 'Verba', ''],
            ['Air', 'Aiwoi', 'Water', $categories[0] ?? 'Verba', ''],
            ['Selamat pagi', 'Ari nggiro', 'Good morning', $categories[0] ?? 'Verba', ''],
        ];

        foreach ($samples as $index => $sample) {
            $row = $index + 2;
            foreach ($sample as $col => $value) {
                $sheet->setCellValue([$col + 1, $row], $value);
            }
        }

        $lastRow = (int) config('dictionary.max_rows') + 1;
        $this->styleDataRows($sheet, $lastRow, count($headers));
        for ($row = 2; $row <= $lastRow; $row++) {
            $validation = $sheet->getCell("D{$row}")->getDataValidation();
            $validation->setType(DataValidation::TYPE_LIST);
            $validation->setErrorStyle(DataValidation::STYLE_STOP);
            $validation->setAllowBlank(true);
            $validation->setShowInputMessage(true);
            $validation->setShowErrorMessage(true);
            $validation->setShowDropDown(true);
            $validation->setErrorTitle('Kategori tidak valid');
            $validation->setError('Pilih kategori dari daftar yang tersedia.');
            $validation->setPromptTitle('Pilih kategori');
            $validation->setPrompt('Pilih salah satu kategori dari daftar.');
            $validation->setFormula1('KategoriKamus');
        }

        foreach (['A' => 28, 'B' => 24, 'C' => 24, 'D' => 20, 'E' => 26] as $column => $width) {
            $sheet->getColumnDimension($column)->setWidth($width);
        }

        $sheet->freezePane('A2');
    }

    private function buildSentenceSheet(Spreadsheet $spreadsheet): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle(config('dictionary.xlsx_sheets.sentence_examples'));

        $headers = config('dictionary.xlsx_headers.sentence_examples');
        $this->writeHeaderRow($sheet, $headers);

        $samples = [
            ['Makan', '', 'Saya sedang makan nasi', 'Inoi monga kade', ''],
            ['Air', '', 'Air di rumah', 'Aiwoi i laika', ''],
            ['Selamat pagi', '', 'Selamat pagi', 'Ari nggiro', ''],
        ];

        foreach ($samples as $index => $sample) {
            $row = $index + 2;
            foreach ($sample as $col => $value) {
                $sheet->setCellValue([$col + 1, $row], $value);
            }
        }

        $this->styleDataRows($sheet, (int) config('dictionary.max_rows') + 1, count($headers));

        foreach (['A' => 24, 'B' => 32, 'C' => 32, 'D' => 32, 'E' => 26] as $column => $width) {
            $sheet->getColumnDimension($column)->setWidth($width);
        }

        $sheet->freezePane('A2');
    }

    private function writeHeaderRow(Worksheet $sheet, array $headers): void
    {
        foreach ($headers as $index => $header) {
            $sheet->setCellValue([$index + 1, 1], $header);
        }

        $lastColumn = $sheet->getCell([count($headers), 1])->getColumn();
        $headerRange = "A1:{$lastColumn}1";

        $sheet->getStyle($headerRange)->applyFromArray([
            'font' => [
                'bold' => true,
                'color' => ['rgb' => 'FFFFFF'],
                'size' => 11,
            ],
            'fill' => [
                'fillType' => Fill::FILL_SOLID,
                'startColor' => ['rgb' => '2563EB'],
            ],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
                'vertical' => Alignment::VERTICAL_CENTER,
            ],
            'borders' => [
                'allBorders' => [
                    'borderStyle' => Border::BORDER_THIN,
                    'color' => ['rgb' => '1E3A8A'],
                ],
            ],
        ]);

        $sheet->getRowDimension(1)->setRowHeight(24);
    }

    private function styleDataRows(Worksheet $sheet, int $lastRow, int $columnCount): void
    {
        $lastColumn = $sheet->getCell([$columnCount, 1])->getColumn();
        $range = "A2:{$lastColumn}{$lastRow}";

        $sheet->getStyle($range)->applyFromArray([
            'font' => ['size' => 11],
            'borders' => [
                'allBorders' => [
                    'borderStyle' => Border::BORDER_THIN,
                    'color' => ['rgb' => 'D1D5DB'],
                ],
            ],
        ]);
    }
}
